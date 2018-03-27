import asyncio
from functools import partial
from time import sleep

async def sleep_for(sec, loop):
    print(f"sleep for {sec} s")
    await loop.run_in_executor(None, partial(sleep, sec))

async def main(loop):
    print("running main")
    await asyncio.gather(
        sleep_for(5, loop),
        sleep_for(2, loop),
    )
    print("done")

if __name__ == '__main__':
    evloop = asyncio.get_event_loop()
    try:
        evloop.run_until_complete(main(evloop))
    finally:
        evloop.close()
