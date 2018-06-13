import os
import socket
import time
import zlib
import struct
import natsort
from PIL import Image
import sys
import Utils


def pairwise(t):
    it = iter(t)
    return zip(it, it)


def chunkifyfile(file, chunk_size=2048):
    while True:
        data = file.read(chunk_size)
        if not data:
            break
        yield data


def preparevideo(gif):
    image = Image.open(gif)
    for _ in range(image.n_frames):
        yield Utils.processframe(image)
        try:
            image.seek(image.tell() + 1)
        except EOFError:
            image.seek(0)
            break


def waituntil(packet, waitsocket, timeout=0.1):
    if packet is None:
        while True:
            buff = waitsocket.recv(1024)
            if buff != b"":
                return buff
    else:
        while True:
            buff = waitsocket.recv(1024)
            if packet == buff:
                return buff


# TO-DO: Optimise some more. [DONE]
def packetbuilder(plist):
    """
    Optimise packet sizes and OC background changing
    Optimisation 1: Reducing total count of background changes in a a frame.
    Optimisation 2: use struct packing
    :param plist:
    :return:
    """
    # TODO: Make this work for structs.
    colorswaps = 0
    sortedlist = natsort.natsorted(plist)
    currentcolor = '0x000000'
    listgrouped = []
    workinglist = []
    # update is now a set.
    for update in sortedlist:
        color, x, y, height, width, sb = update
        x = str(x).zfill(3)
        y = str(y).zfill(3)
        h = str(height).zfill(3)
        w = str(width).zfill(3)
        sb = str(sb)
        if color != currentcolor and workinglist != []:
            # currentcolor, *workinglist
            listgrouped.append(struct.pack(''.join(['<', '8s', '13s' * (len(workinglist))]),
                                           currentcolor.encode(encoding='utf-8'), *workinglist))
            currentcolor = color
            # Reset and add it as well.
            workinglist = [f"{x}{y}{h}{w}{sb}".encode(encoding='utf-8')]
            colorswaps += 1
        else:
            workinglist.append(f"{x}{y}{h}{w}{sb}".encode(encoding='utf-8'))
    # flush working buffer.
    listgrouped.append(struct.pack(''.join(['<', '8s', '13s' * (len(workinglist))]),
                                   currentcolor.encode(encoding='utf-8'), *workinglist))
    del workinglist
    return listgrouped


class PacketHandler:
    """
    Main Packet Handling. aka Server to Client interaction.
    """

    def __init__(self, ipbind='0.0.0.0', portbind=25652, video='vesperia.gif', audio='vesperia.dfpwm'):

        self.bind_ip = ipbind
        self.bind_port = portbind
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.bind((self.bind_ip, self.bind_port))
        self.server.listen(5)
        # Client Requested BufferSize
        self.buffersize = 30
        self.frame = 0
        self.video = video
        self.initframe = None
        self.updates = None
        self.audiopath = audio
        print("Preparing video...")
        self.frames = preparevideo(self.video)
        print("Prep OK starting server...")
        self.latency = 0
        self.start()

    def attemptconnect(self):
        print("Waiting for Connection")
        client_sock, address = self.server.accept()
        print(f"Recieved connection from: {address}. Sending Server Info")
        self.latency = time.time()
        client_sock.send(b"OCRCNT/1.0.0")
        return client_sock.recv(1024)

    def start(self):
        print("Waiting for Connection")
        client_sock, address = self.server.accept()
        self.latency = time.time()
        print(f"Recieved connection from: {address}. Sending Server Info")
        client_sock.send(b"OCRCNT/1.0.0")
        while True:
            try:
                buffer = client_sock.recv(1024)
            except ConnectionError:
                buffer = self.attemptconnect()
            print(buffer)
            if buffer == b"READY":
                self.latency = time.time() - self.latency
                print(f"Latency: {self.latency} [PingPong]")
            elif buffer == b"CAP":
                # list cpabilities
                client_sock.send(f"{1 if self.video else 0}{1 if self.audiopath else 0}".encode(encoding='utf-8'))
            elif buffer == b"AUDIO":
                # TODO: DFPWM Surround Sound for OC support
                print("Client Requested Audio file")
                file = open(self.audiopath, 'rb')
                readsize = 2048
                client_sock.send(str(os.path.getsize(self.audiopath)).encode('utf-8'))
                waituntil(b"SEND", client_sock)
                for chunk in chunkifyfile(file, readsize):
                    client_sock.send(chunk)
                print("Finished Sending packets. Waiting for confirmation.")
                waituntil(b"OK", client_sock)
                print("Client Reports OK. Waiting for further instructions.")
            elif b"PACK" in buffer:
                str(buffer)
                print("Sending packet!")
                for _ in range(self.frame, self.frame + self.buffersize):
                    frame = next(self.frames)
                    client_sock.send((b''.join(packetbuilder(frame)) + b"|"))
                    print(f"sent frame")
                self.frame += self.buffersize
            elif buffer == b'':
                sys.exit(0)
            else:
                print(f"Unrecognised function: {buffer}")


if __name__ == '__main__':
    PacketHandler(video=sys.argv[1], audio=sys.argv[2], ipbind=sys.argv[3])
