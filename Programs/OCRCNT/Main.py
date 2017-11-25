import socket
import zlib
import sys
import os
import struct

bytes = {"F": 46, "U": 55}
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('192.168.0.100', 25561)
sock.bind(server_address)
sock.listen(1)
# Profiling REsults for Client:
# 306 sets per tick, 171 fills, 91 copies
try:
    open("imagearray.txt", "r")
except FileNotFoundError:
    print("404 File not found.")
    sys.exit(1)
while True:
    print("Waiting for Connection...")
    connection, cliaddr = sock.accept()
    print(f"Connection Found From: {cliaddr}")
    connection.send(b"OCRCNT")
    with open("Instructions.txt", "r") as ia:
        while True:
            try:
                buff = connection.recv(1024)
            except ConnectionResetError:
                print("Connect was Reset. This is 100% Ok.")
                break
            if buff in [b"DATA\n", b"DATA"]:
                print("DATA")
                ia.seek(0)
                palette = f"{ia.readline()}"
                size = f"{ia.readline()}"
                print(size.encode())
                palette = zlib.compress(palette.encode())
                connection.send(struct.pack('<I', len(palette)))
                for x in [palette[i:i + 1000] for i in range(0, len(palette), 1000)]:
                    connection.send(x)
                connection.send(size.encode())
            elif buff in [b"AUDIO\n", b"AUDIO"]:
                print("AUDIO")
                connection.send(str(os.stat("Instructions.dfpwm").st_size).encode())
                os.stat("Instructions.dfpwm")
                dfpwm = open("Instructions.dfpwm", "rb")
                print("Opened File")
                if connection.recv(1024) in [b"STOP", b"STOP\n"]:
                    print("STOP")
                    pass
                else:
                    print("passed")
                    piececount = 0
                    while True:
                        piece = dfpwm.read(2048)
                        if piece == b"":
                            connection.send(b"AOK")
                            break
                        else:
                            piececount += 1
                            print(f"send piece: {piececount}")
                            connection.send(piece)
                dfpwm.close()
                print("done sending")
                print("send packet")
            elif buff in [b"NXT\n", b"NXT"]:
                while True:
                    instruction = ia.readline()
                    instructlist = instruction.split("&")
                    # Ignore Rest of instructions
                    for x in instructlist:
                        if x[0] == "F":
                            header = b"U"
                            bxcoord = "".join([str(int(x[1:4:])), ","]).encode()
                            bycoord = "".join([str(int(x[4:7:])), ","]).encode()
                            bwidth = "".join([str(int(x[7:10:])), ","]).encode()
                            bheight = "".join([str(int(x[10:13:])), ","]).encode()
                            bpalette = "".join([str(int(x[13:17:])), ","]).encode()
                            connection.send(b"".join([header, b",", bxcoord, b",", bycoord, b",", bwidth, b",", bheight, b",", bpalette]))
                        else:
                            print("Invalid Packet Header!")
            elif buff == b"":
                print("Connection lost. Totally Fine as well.")
                break
            else:
                print(f"Recieved Unknown Packet: {buff}")
