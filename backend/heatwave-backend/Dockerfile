FROM haskell:9.6

WORKDIR /app

COPY . /app/backend/heatwave-backend

WORKDIR /app/backend/heatwave-backend

RUN cabal update
RUN cabal build

EXPOSE 3000

CMD ["cabal","run","heatwave-backend"]