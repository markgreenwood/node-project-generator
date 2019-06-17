import * as Hapi from "@hapi/hapi";

const server: Hapi.Server = new Hapi.Server({ host: "localhost", port: 3000 });

server.route([
  {
    method: "GET",
    path: "/health",
    handler: () => ({ status: "OK" }),
  },
]);

server.start().then(() => {
  console.log(`Server started and running on ${server.info.uri}`);
});

export default server;
