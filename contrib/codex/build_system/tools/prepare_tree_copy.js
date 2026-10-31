#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'../../../..'),base=path.resolve(__dirname,'..'),catalog=require('../data/catalog.json');
const names={
 'The Song Splits':'The Brood Splits','Sung Before the Strike':'Spawn Before the Strike','The Verse Bites Twice':'The Brood Bites Twice',
 'Nine Throats, One Verse':'Nine Throats, One Hunger','The Song Does Not End':'The Brood Remains','The Pack Sings One Prey':'The Pack Names One Prey',
 'Frenzy Feeds the Verse':'Frenzy Feeds the Pack','The Verse Turns Red':'The Brood Turns Red','Skin Before Song':'Skin Before Scars',
 'The Verse Refuses Holes':'The Flesh Refuses Holes','What Was Sung Grows Back':'What Was Cut Grows Back','Sung in Rounds':'Spit in Two Waves',
 'Verses Assigned at Hatching':'Instincts Assigned at Hatching','The Flagship Sings First':'The Flagship Acts First','Throat of the Deep Song':'Throat of the Deep',
 'Broods Sing the Strike Order':'Broods Set the Strike Order','The Throng Sings the Flagship Whole':'The Throng Grows the Flagship Whole'
};
const changes=[],files=new Map();
for(const skill of catalog.skills){
 if(!skill.owner.members.some(id=>['matriarch','razormaw','mending','voice'].includes(id)))continue;
 let after=skill.original;
 if(names[skill.name])after=after.replace(skill.name,names[skill.name]);
 after=after.replace(/may be sung/g,'may be released').replace(/when the tide is sung/g,'when the tide is released').replace(/give each ship a verse /g,'give each ship an instinct ').replace(/change its verse/g,'change its instinct');
 if(after===skill.original)continue;
 if(!files.has(skill.source.path))files.set(skill.source.path,fs.readFileSync(path.join(root,skill.source.path),'utf8').replace(/\r\n/g,'\n').split('\n'));
 const lines=files.get(skill.source.path);assert(lines[skill.source.line-1].includes(skill.original));lines[skill.source.line-1]=lines[skill.source.line-1].replace(skill.original,after);
 changes.push({id:skill.id,source:skill.source,before:skill.original,after,reason:'Lore Bible r8:333 forbids song words in Chorus names/lines.',mechanicsChanged:false,status:'proposed_copy_edit'});
}
const headerChanges=[];
for(const [file,lines] of files){
 let chorus=false;
 for(let i=0;i<lines.length;i++){
  if(lines[i].startsWith('## '))chorus=lines[i]==='## The Chorus';
  if(chorus&&lines[i].startsWith('Branch A - ')&&/Verse/.test(lines[i])){const before=lines[i];lines[i]=lines[i].replace('The Verse of Too Many Mouths','The Hunger of Too Many Mouths').replace(/Verse/g,'Instinct');headerChanges.push({file,line:i+1,before,after:lines[i]});}
 }
 const target=path.join(base,'candidates/tree_copy',file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,'> Codex proposed copy edit against main 355a2ac7. Slot/header edits are enumerated in contrib/codex/build_system/data/tree_copy_edits.json. Mechanics and original provenance notes are retained; this is not the canonical Muse file.\n\n'+lines.join('\n'));
}
fs.writeFileSync(path.join(base,'data/tree_copy_edits.json'),JSON.stringify({authority:'contrib/opus/compute/lore_bible_r8.md:333',sourcePin:'355a2ac7',changes,headerChanges},null,2)+'\n');
console.log(changes.length+' slot copy edits and '+headerChanges.length+' branch headings; mechanics/provenance preserved in proposed full copies');
