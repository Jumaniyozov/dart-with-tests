import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createMDX } from 'fumadocs-mdx/next';

const dir = path.dirname(fileURLToPath(import.meta.url));
/** The book's code samples live in ../code and are transcluded into MDX,
 *  so module resolution has to reach one level above this app. */
const repoRoot = path.join(dir, '..');

const withMDX = createMDX();

/** @type {import('next').NextConfig} */
const config = {
  reactStrictMode: true,
  devIndicators: false,
  turbopack: { root: repoRoot },
  outputFileTracingRoot: repoRoot,
};

export default withMDX(config);
