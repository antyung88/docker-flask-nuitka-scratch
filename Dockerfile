#syntax=docker/dockerfile-upstream:1.4.0-rc1
FROM debian:bullseye-slim as base

COPY ./app /code/app

RUN apt-get update -y \
    && apt-get install --no-install-recommends -y \
        python3.9 \
        python3-venv \
        python3.9-dev \
        build-essential \
        ccache \
        clang \
        libfuse-dev \
        upx \
        patchelf \
        && rm -rf /var/cache/apt/archives

ENV VIRTUAL_ENV=/code
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN . /code/bin/activate

COPY ./requirements.txt .

RUN pip3 install -r requirements.txt \
    && python3.9 -m pip install nuitka \
    && python3.9 -m pip install ordered-set

WORKDIR /code/app

RUN python3.9 -m nuitka \
        --onefile \
        --onefile-tempdir \
        --follow-imports \
        main.py

FROM scratch
ENV PATH="/bin:${PATH}"
COPY --from=ghcr.io/antyung88/scratch-sh:stable /lib /lib
COPY --from=ghcr.io/antyung88/scratch-sh:stable /bin /bin

COPY --from=base /var/app/main.bin /main.bin
COPY --from=base /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=base /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=base /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=base /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=base /lib/x86_64-linux-gnu/libutil.so.1 /lib/x86_64-linux-gnu/libutil.so.1
COPY --from=base /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0
COPY --from=base /tmp /tmp

EXPOSE 8080
ENTRYPOINT [ "/main.bin" ]
