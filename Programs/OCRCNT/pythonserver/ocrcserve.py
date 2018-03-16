import socket

import numpy
from PIL import Image

import Utils


def pairwise(t):
    it = iter(t)
    return zip(it, it)

def gifyielder(gifpil):
    while gifpil.tell() < gifpil.n_frames:
        yield gifpil
        try:
            gifpil.seek(gifpil.tell() + 1)
        except EOFError:
            gifpil.seek(0)
            break

def preparevideo(gif):
    videodata = []
    image = Image.open(gif)
    initframe = Utils.processframe(image)
    for frame in gifyielder(image):
        Utils.processframe(frame)
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

def packetcreate(createfillersarray):
    pass
    # to be continued!

class PacketHandler:
    def __init__(self,ipbind='0.0.0.0',portbind=25652):
        self.bind_ip = ipbind
        self.bind_port = portbind
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.bind((self.bind_ip, self.bind_port))
        self.server.listen(5)
        self.buffersize = None
        self.frame = 0
        self.video = 'vesperia.gif'
        self.initframe = None
        self.updates = None

    def start(self):
        client_sock, address = self.server.accept()
        print(f"Recieved connection from: {address} | {client_sock}")
        client_sock.send(b"OCRCNT")
        while True:
            try:
                buffer = client_sock.recv(1024)
            except ConnectionResetError:
                print("Waiting for Connection: [Connection Reset]")
                client_sock, address = self.server.accept()
                print(f"Client just (re)connected: {address}")
                buffer = client_sock.recv(1024)
            if buffer == b"READY":
                print("Send Ready command. listening for buffersizes...")
                client_sock.send(b"BSIZE?")
                size = waituntil(None,client_sock)
                print(f"Buffersize: {int(size.decode('utf-8'))}")
                self.buffersize = int(size.decode('utf-8'))
            elif buffer == b"Packet":
                pass
                # to be continued!
    def prep(self):
        self.initframe, self.updates = preparevideo(self.video)