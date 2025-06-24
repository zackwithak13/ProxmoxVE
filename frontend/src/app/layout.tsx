import Footer from "@/components/Footer";
import Navbar from "@/components/Navbar";
import QueryProvider from "@/components/query-provider";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import { analytics, basePath } from "@/config/siteConfig";
import "@/styles/globals.css";
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { NuqsAdapter } from "nuqs/adapters/next/app";
import React from "react";

const inter = Inter({ subsets: ["latin"] });

export const metadata : Metadata = {
  title: "Proxmox VE Helper-Scripts",
  description:
    "The official website for the Proxmox VE Helper-Scripts (Community) Repository. Featuring over 300+ scripts to help you manage your Proxmox VE environment.",
  applicationName: "Proxmox VE Helper-Scripts",
  generator: "Next.js",
  referrer: "origin-when-cross-origin",
  keywords: [
    "Proxmox VE",
    "Helper-Scripts",
    "tteck",
    "helper",
    "scripts",
    "proxmox",
    "VE",
    "virtualization",
    "containers",
    "LXC",
    "VM",
  ],
  authors: [
    { name: "Bram Suurd", url: "https://github.com/BramSuurdje" },
    { name: "Community Scripts", url: "https://github.com/Community-Scripts" },
  ],
  creator: "Bram Suurd",
  publisher: "Community Scripts",
  metadataBase: new URL(`https://community-scripts.github.io/${basePath}/`),
  alternates: {
    canonical: `https://community-scripts.github.io/${basePath}/`,
  },
  viewport: {
    width: "device-width",
    initialScale: 1,
    maximumScale: 5,
  },
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    title: "Proxmox VE Helper-Scripts",
    description:
      "The official website for the Proxmox VE Helper-Scripts (Community) Repository. Featuring over 300+ scripts to help you manage your Proxmox VE environment.",
    url: `https://community-scripts.github.io/${basePath}/`,
    siteName: "Proxmox VE Helper-Scripts",
    images: [
      {
        url: `https://community-scripts.github.io/${basePath}/defaultimg.png`,
        width: 1200,
        height: 630,
        alt: "Proxmox VE Helper-Scripts",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Proxmox VE Helper-Scripts",
    creator: "@BramSuurdje",
    description:
      "The official website for the Proxmox VE Helper-Scripts (Community) Repository. Featuring over 300+ scripts to help you manage your Proxmox VE environment.",
    images: [`https://community-scripts.github.io/${basePath}/defaultimg.png`],
  },
  manifest: "/manifest.webmanifest",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Proxmox VE Helper-Scripts",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script defer src={`https://${analytics.url}/script.js`} data-website-id={analytics.token}></script>
        <link rel="canonical" href={metadata.metadataBase?.href} />
        <link rel="manifest" href="manifest.webmanifest" />
        <link rel="preconnect" href="https://api.github.com" />
      </head>
      <body className={inter.className}>
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem disableTransitionOnChange>
          <div className="flex w-full flex-col justify-center">
            <Navbar />
            <div className="flex min-h-screen flex-col justify-center">
              <div className="flex w-full justify-center">
                <div className="w-full max-w-[1440px] ">
                  <QueryProvider>
                    <NuqsAdapter>{children}</NuqsAdapter>
                  </QueryProvider>
                  <Toaster richColors />
                </div>
              </div>
              <Footer />
            </div>
          </div>
        </ThemeProvider>
      </body>
    </html>
  );
}
