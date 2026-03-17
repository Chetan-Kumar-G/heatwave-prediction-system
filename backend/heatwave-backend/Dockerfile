FROM haskell:9.2

WORKDIR /app

COPY backend/heatwave-backend /app

RUN cabal update
RUN cabal build

EXPOSE 3000

CMD ["cabal", "run", "heatwave-backend"]