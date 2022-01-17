import express from "express";
import { createServer } from "http";
import { Server } from "socket.io";
import fetch from "node-fetch";

const app = express();
const server = createServer(app);
const io = new Server(server, {
  allowEIO3: true,
});

const apiKey = "{{ API_KEY }}";
const limit = 10;
const currencyListUrl = `https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?CMC_PRO_API_KEY=${apiKey}&limit=${limit}`;

io.on("connection", (socket) => {
  console.log("a user connected");
  fetchList(socket);
  socket.on("get-new-currency-list", () => {
    fetchList(socket);
  });
});

const fetchList = (socket) => {
  fetchCurrencList().then((currencyList) => {
    socket.emit("fetched-currency-list", { list: currencyList });
  });
};

const fetchCurrencList = () =>
  new Promise((resolve, reject) => {
    console.log("List fetched");
    fetch(currencyListUrl)
      .then((res) => res.json())
      .then((res) => resolve(res))
      .catch((error) => reject(error));
  });

server.listen(5000, () => {
  console.log("socket run on 5000: http://localhost:5000");
});
