import asyncio
import websockets

from sys import argv

async def clisten(uri):
    async with websockets.connect(uri) as ws:
        async for message in ws:
            print(f"got {message}")


if __name__ == '__main__':
    uri = 'ws://localhost:{}/ws'.format(argv[1])
    print(f"listening for messages on {uri}")
    asyncio.get_event_loop().run_until_complete(clisten(uri))
