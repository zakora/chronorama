import asyncio
import websockets

from random import randint
from sys import stdin
from time import sleep


# async def send_pos(websocket, path):
#     i = 0
#     while True:
#         await asyncio.sleep(1 / 5)
#         pos = str(i)
#         i += 1
#         await websocket.send(pos)
#     print("=== DONE ===")


async def proxy(websocket, _path):
    while True:
        msg = stdin.readline()
        await websocket.send(msg)


start_server = websockets.serve(proxy, 'localhost', 8899)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
