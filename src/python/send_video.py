import cv2 as cv
import socket
import time
import math
import os

# FILE = "../data/SampleVideo_640x480_1mb.mp4"
directory = "../data/Yosan/"
FILE = "../data/Yosan.mp4"
LABEL = "../data/Yosan.txt" # "../data/prediction_230_BIG.txt" # "../data/prediction_230.txt"
PACKET_SIZE = 1452
HOST, PORT = "192.168.50.8", 1234

# vidcap = cv.VideoCapture(FILE)
FPS = 30 #round(vidcap.get(cv.CAP_PROP_FPS))
label_FPS = 5

with open(LABEL, 'r') as file:
    video_speed = [int(float(line.strip())) for line in file]

for i in range(len(video_speed)):
    if (video_speed[i] < 0):
        video_speed[i] = 0

# success, frame = vidcap.read()

frame = cv.imread(os.path.join(directory, f"Yosan_000001.png"))
height, width, channels = frame.shape
DISPLAY_WIDTH = 640
DISPLAY_HEIGHT = 480

# ethernet connection
client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
client.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 8192)
client.connect((HOST, PORT))

frame_read = 1
frame_sent = 0
packet_count = 0
R_last = 0

def number_to_fixed_tuple(n, length=8):
    digits = str(abs(n)).zfill(length)[:length]
    return tuple(int(d) for d in digits)

print("Start sending video (size = %d x %d) at {FPS} FPS" % (DISPLAY_WIDTH, DISPLAY_HEIGHT))
start_time = time.time()

user_speed = 0.1
reuse_count = 0
direction = 1
correct_stop = 1
start = 1
flag = 0
send_distance = 0
neg_sign = 0
target_time_start = time.time()

while True:
    fps_start = time.time()

    # === Calculate Distance ===
    i = frame_read * label_FPS / FPS
    distance = 0.0
    while video_speed[int(i)] > 0:
        distance += 100 * video_speed[int(i)] * 1000 / 3600 / label_FPS
        i += 1

    i = frame_read * label_FPS / FPS
    distance_prev = 0.0
    while video_speed[int(i)] > 0:
        distance_prev += 100 * video_speed[int(i)] * 1000 / 3600 / label_FPS
        i -= 1
    print(f"Distance = { int(distance) } cm, Distance_prev = { int(distance_prev) } cm")

    if distance < distance_prev:
        flag = 1

    if ( user_speed == 0 and (distance < 300 or distance_prev < 300) ):
        correct_stop = 1
        start = 1
    elif ( user_speed != 0):
        if distance > distance_prev:
            correct_stop = 0
        if (distance < distance_prev and correct_stop == 0):
            start = 0

    if (start == 1 and user_speed > 0):
        if (distance > distance_prev):
            send_distance = distance
    elif (start == 0 and user_speed > 0):
        if (distance < distance_prev):
            send_distance = distance
        else:
            send_distance = distance_prev

    if distance > distance_prev:
        if start == 0: 
            neg_sign = 1
        elif correct_stop == 1 and flag == 1:
            neg_sign = 1   

    # === Sync to user speed ===
    if reuse_count == 0:
        if user_speed != 0:
            # frame preprocess
            # Only pad if the image is smaller
            if height < DISPLAY_HEIGHT or width < DISPLAY_WIDTH:
                top = (DISPLAY_HEIGHT - height) // 2
                bottom = DISPLAY_HEIGHT - height - top
                left = (DISPLAY_WIDTH - width) // 2
                right = DISPLAY_WIDTH - width - left

                frame = cv.copyMakeBorder(
                    frame,
                    top, bottom, left, right,
                    borderType=cv.BORDER_CONSTANT,
                    value=(0, 0, 0)  # Black pixels
                )

            # flatten image directly (BGR)
            flat_frame = frame.flatten()
            total_length = len(flat_frame)

        if (user_speed == 0):
            target_time = 1.0 / (FPS*2)
            reuse_count = 2

        elif (video_speed[int(frame_read*label_FPS/FPS)] == 0) : 
            target_time = 1.0 / (FPS*2)
            reuse_count = 2
            while (video_speed[int(frame_read*label_FPS/FPS)] == 0):
                frame_read += 1 * direction
            
        elif (user_speed <= video_speed[int(frame_read*label_FPS/FPS)]) :
            reuse_count = 2 * video_speed[int(frame_read*label_FPS/FPS)] // user_speed
            NEW_FPS = (FPS / video_speed[int(frame_read*label_FPS/FPS)] * user_speed * reuse_count)
            target_time = 1.0 / (NEW_FPS*2)

        else:    
            increment = math.ceil( user_speed / video_speed[int(frame_read*label_FPS/FPS)] )
            
            NEW_FPS = (FPS / video_speed[int(frame_read*label_FPS/FPS)] * user_speed) / increment
            target_time = 1.0 / (NEW_FPS*2)
            reuse_count = 2

            for i in range(1, increment):
                frame_read += 1 * direction

    # === Sync to target time ===
    elapsed = time.time() - target_time_start
    remaining = target_time - elapsed
    if remaining > 0:
        time.sleep(remaining)
    target_time_start = time.time()
    
    # Reset frame counter
    frame_sent += 1

    # Optional debug for last red pixel
    R_last = flat_frame[-1]

    # Send in PACKET_SIZE chunks
    for i in range(0, total_length, PACKET_SIZE):    # 635 packets / frame
        chunk = flat_frame[i:i + PACKET_SIZE]
        if not client.send(chunk):
            print("Error occurred")
        packet_count += 1
    
    dist_digit = number_to_fixed_tuple(int(send_distance))
    #dist_bytes = (int(distance)).to_bytes(3, byteorder='big')
    combined_dist = bytes(dist_digit)
    client.send(combined_dist)

    client.settimeout(1)  # wait up to 5 seconds for a response
    try:
        # We assume that any response does not exceed 4096 bytes.
        data_return, address = client.recvfrom(4096)
        data0 = data_return[0]
        data1 = data_return[1]
        if (data0 >= 128):
            data0 = data0 - 128
            if (data0 >= 64): 
                direction = 1
                data0 = data0 - 64
            else :
                direction = -1
            user_speed = data0 * 8 + data1 // 16
        else:
            data1 = data1 - 128
            if (data1 >= 64):
                data1 = data1 - 64
                direction = 1
            else:
                direction = -1
            user_speed = data1 * 8 + data0 // 16
        # print("Received data from {}: {}, {}".format(address, direction, user_speed))
    except socket.timeout:
        print("No response received within 1 seconds.")

    reuse_count = reuse_count - 1

    if reuse_count == 0 and user_speed != 0:
        frame = cv.imread(os.path.join(directory, f"Yosan_{frame_read:06d}.png"))
        frame_read += 1 * direction

send_time = time.time() - start_time

print("Last byte (R) =", R_last)
print("Time costed = %.2f s" % send_time)
print("Total %d packets sent to %s" % (packet_count, HOST))
print("Total %d frames sent to %s" % (frame_sent, HOST))
print("Average FPS = %.2f" % (frame_sent / send_time))
print("The video has been sent to %s" % HOST)

client.close()
