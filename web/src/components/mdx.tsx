import defaultMdxComponents from 'fumadocs-ui/mdx';
import type { MDXComponents } from 'mdx/types';
import { Console, Direction, Drill, Gloss, Practice } from './press';

export function getMDXComponents(components?: MDXComponents) {
  return {
    ...defaultMdxComponents,
    Drill,
    Direction,
    Gloss,
    Practice,
    Console,
    ...components,
  } satisfies MDXComponents;
}

export const useMDXComponents = getMDXComponents;

declare global {
  type MDXProvidedComponents = ReturnType<typeof getMDXComponents>;
}
