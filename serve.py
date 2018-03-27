import asyncio

from random import randint
from sys import stdin

from sanic import Sanic
from sanic import response

app = Sanic()


# Main app
app.static('/', './main.html', name='main.html')


# Websocket
@app.websocket('/ws')
async def proxy(_request, ws):
    while True:
        # loop = asyncio.get_event_loop()
        # msg = await loop.run_in_executor(None, stdin.readline)
        msg = str(randint(-100, 100))
        await ws.send(msg)
        await asyncio.sleep(1 / 5)


if __name__ == '__main__':
    app.run(host='localhost', port=8899)
