import * as Hapi from "@hapi/hapi";

const init = async (server: Hapi.Server) => {
  await server.start();
  console.log("Server running on port: ", server.info.uri);
};

const server: Hapi.Server = new Hapi.Server({ host: "localhost", port: 3000 });

server.route([
  {
    method: "GET",
    path: "/health",
    handler: () => ({ status: "OK" }),
  },
]);

process.on("unhandledRejection", err => {
  console.log(err);
  process.exit(1);
});

if (require.main === module) {
  init(server);
  console.log(`Server started and running on ${server.info.uri}`);
}

export default server;
