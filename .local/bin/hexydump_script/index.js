#!/usr/bin/env node

const hexy = require("hexy");
const fs = require("fs");

const [, , input] = process.argv;

if (!input) process.exit(1);

console.log(hexy.hexy(fs.readFileSync(input), { littleEndian: true }));
