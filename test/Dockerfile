# syntax=docker/dockerfile:1

# ── Build-time defaults (override with --build-arg) ──────────────────────
ARG UNAME=iamveen
ARG UID=1000
ARG GID=1000

FROM ubuntu:25.10

# Carry args into build scope
ARG UNAME
ARG UID
ARG GID

# ── Rename the default ubuntu user (UID 1000) or create a new one ─────────
RUN apt-get update \
 && apt-get install -y --no-install-recommends sudo \
 && rm -rf /var/lib/apt/lists/* \
 && if [ "$UID" = "1000" ]; then \
      groupmod -g "$GID" -n "$UNAME" ubuntu \
      && usermod -l "$UNAME" -d /home/"$UNAME" -m ubuntu; \
    else \
      deluser --remove-home ubuntu \
      && groupadd -g "$GID" "$UNAME" \
      && useradd -u "$UID" -g "$GID" -m -d /home/"$UNAME" -s /bin/bash "$UNAME"; \
    fi \
 && echo "$UNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$UNAME" \
 && chmod 0440 /etc/sudoers.d/"$UNAME"

# ── Workdir ───────────────────────────────────────────────────────────────
WORKDIR /home/$UNAME

# ── Default user & shell ─────────────────────────────────────────────────
USER $UNAME

CMD ["bash"]
