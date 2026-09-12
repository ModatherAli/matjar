import swaggerJSDoc from "swagger-jsdoc";

const options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Matjar E-commerce API",
      version: "1.0.0",
      description:
        "REST API for the Matjar e-commerce platform: storefront, cart, orders, reviews and admin management.",
    },
    servers: [{ url: "http://localhost:4000", description: "Local dev" }],
    tags: [
      { name: "Health" },
      { name: "Auth" },
      { name: "Users" },
      { name: "Categories" },
      { name: "Products" },
      { name: "Addresses" },
      { name: "Cart" },
      { name: "Orders" },
      { name: "Reviews" },
      { name: "Admin" },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
        },
      },
    },
  },
  apis: ["./src/docs/*.docs.js"],
};

export const swaggerSpec = swaggerJSDoc(options);

