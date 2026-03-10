import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      // Local development
      {
        protocol: "http",
        hostname: "localhost",
        port: "8000",
        pathname: "/uploads/**",
      },
      {
        protocol: "http",
        hostname: "localhost",
        port: "3000",
        pathname: "/**",
      },
      // Cloudinary (production image storage)
      {
        protocol: "https",
        hostname: "res.cloudinary.com",
        pathname: "/**",
      },
      // Render backend (in case of local-storage fallback)
      {
        protocol: "https",
        hostname: "*.onrender.com",
        pathname: "/uploads/**",
      },
    ],
  },
};

export default nextConfig;
