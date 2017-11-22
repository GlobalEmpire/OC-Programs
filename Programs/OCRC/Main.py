import socket
from OCRS import constant
import zlib
import sys
import os
import struct
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = (socket.gethostbyname(socket.gethostname()), 25561)
sock.bind(server_address)
sock.listen(1)
print(f"Serveing at: {socket.gethostbyname(socket.gethostname())}:25561")
try:
    open("imagearray.txt", "r")
except FileNotFoundError:
    print("ImageArray File not found.")
    sys.exit(1)
while True:
    print("Waiting for Connection...")
    connection, cliaddr = sock.accept()
    print(f"Connection Found From: {cliaddr}")
    connection.send(b"OCRS")
    with open("imagearray.txt", "r") as ia:
        while True:
            try:
                buff = connection.recv(1024)
            except ConnectionResetError:
                print("Connect was Reset. This is 100% Ok.")
                break
            if buff in [b"READY\n", b"READY"]:
                print("READY")
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
                try:
                    connection.send(str(os.stat("imagearray.dfpwm").st_size).encode())
                    os.stat("imagearray.dfpwm")
                    dfpwm = open("imagearray.dfpwm", "rb")
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
                except FileNotFoundError:
                    connection.send("404")
            elif buff in [b"NXT\n", b"NXT"]:
                print("NXT")
                line = ia.readline()
                if line == "":
                    connection.send(b"FIN")
                    connection.close()
                    break
                else:
                    for x in [line[i:i + 1024] for i in range(0, len(line), 1024)]:
                        zlibbed = zlib.compress(x.encode())
                        connection.send(struct.pack('<I', len(zlibbed)))
                        connection.send(zlibbed)
                    print("Done Sending.")
            elif buff == b"":
                print("Connection lost. Totally Fine as well.")
                break
            else:
                print(f"Recieved Unknown Packet: {buff}")
