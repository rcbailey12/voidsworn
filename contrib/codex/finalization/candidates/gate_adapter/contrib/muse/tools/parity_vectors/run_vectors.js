#!/usr/bin/env node
'use strict';
// Installed location: contrib/muse/tools/parity_vectors/run_vectors.js.
// Always run the checked runtime. Never enable a candidate lane from the gate.
const path=require('path');
const root=path.resolve(__dirname,'../../../..');
try{process.exitCode=require(path.join(root,'contrib/codex/finalization/tools/run_vectors.js')).cli(process.argv.slice(2));}
catch(e){console.error('INCOMPLETE: '+e.message);process.exitCode=2;}
