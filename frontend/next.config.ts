import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Exportación estática: el panel es 100 % cliente y se sirve como sitio estático (Render).
  output: "export",
  trailingSlash: true,
  images: { unoptimized: true },
};

export default nextConfig;
