import socket

import numpy
import os
import time
from PIL import Image
import natsort
import Utils
import zlib
from tqdm import tqdm


def pairwise(t):
    it = iter(t)
    return zip(it, it)


def gifyielder(gifpil, offset=1):
    gifpil.seek(offset)
    while gifpil.tell() != gifpil.n_frames:
        yield gifpil
        try:
            gifpil.seek(gifpil.tell() + 1)
        except EOFError:
            gifpil.seek(0)
            break


def chunkifyfile(file, chunk_size=2048):
    while True:
        data = file.read(chunk_size)
        if not data:
            break
        yield data


def preparevideo(gif):
    videodata = []
    image = Image.open(gif)
    initframe = Utils.processframe(image)
    with tqdm(desc='Frames Done', total=image.n_frames) as pbar:
        for frame in gifyielder(image):
            videodata.append(Utils.processframe(frame))
            pbar.update(1)
    return initframe, videodata


def waituntil(packet, waitsocket):
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


def packetbuilder(plist):
    """
    Optimise packet sizes and OC background changing
    Optimisation: Reducing total count of background changes in a a frame.
    :param plist:
    :return:
    """
    colorswaps = 0
    sortedlist = natsort.natsorted(plist)
    currentcolor = '#000000'
    listgrouped = []
    workinglist = []
    for x in sortedlist:
        color, mincoord, maxcord, _ = x.split('|')
        if color != currentcolor and workinglist != []:
            listgrouped.append(f'{currentcolor}|{"|".join(workinglist)}')
            currentcolor = color
            workinglist = []
            colorswaps += 1
        else:
            workinglist.append(f'[{mincoord},{maxcord}]')
    # flush working buffer.
    listgrouped.append(f'{currentcolor}|{"|".join(workinglist)}')
    return '/'.join(listgrouped), colorswaps


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
        self.buffersize = None
        self.frame = 0
        self.video = video
        self.initframe = None
        self.updates = None
        self.audiopath = audio
        # Client's Packet Size. Restricted by the Server.
        self.clientsize = None
        self.prep()

    def start(self):
        client_sock, address = self.server.accept()
        print(f"Recieved connection from: {address}. Sending Server Info")
        client_sock.send(b"OCRCNT/1.0.0")
        latency = time.time()
        while True:
            try:
                buffer = client_sock.recv(1024)
            except ConnectionResetError:
                latency = time.time() - latency
                print(f"Latency: {latency} [PingPong]")
                print("Waiting for Connection: [Connection Reset]")
                client_sock, address = self.server.accept()
                print(f"Client connected: {address}")
                buffer = client_sock.recv(1024)
            if buffer == b"READY":
                print("Client is ready. Asking for Buffer sizes...")
                client_sock.send(b"BSIZE?")
                packetsize = waituntil(None, client_sock)
                print(f"Recieved Requested Bffersize for frames: {int(packetsize.decode('utf-8'))}")
                self.buffersize = int(packetsize.decode('utf-8'))
            elif buffer == b"AUDIO":
                print("Client Requested Audio.")
                file = open(self.audiopath, 'rb')
                readsize = waituntil(None, client_sock)
                client_sock.send(str(os.path.getsize(self.audiopath)).encode('utf-8'))
                for chunk in chunkifyfile(file, readsize):
                    client_sock.send(chunk)
                print("Finished Sending packet waiting for confirmation.")
                waituntil(b"OK", client_sock)
                print("Client Reports OK. Waiting for further instructions.")
            elif buffer == b"PACK":
                print("Sending packet!")
                if self.frame == 0:
                    client_sock.send(zlib.compress(self.initframe)[0])
                    for x in self.updates[:self.frame + self.buffersize]:
                        client_sock.send(zlib.compress(packetbuilder(x)[0]))
                        waituntil(b"OK", client_sock)

    def debugpacket(self):
        return

    def prep(self):
        self.initframe, self.updates = preparevideo(self.video)
