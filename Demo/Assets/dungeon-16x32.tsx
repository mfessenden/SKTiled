<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.2" tiledversion="1.2.0" name="dungeon-16x32" tilewidth="16" tileheight="32" tilecount="10" columns="5">
 <tileoffset x="0" y="-6"/>
 <image source="dungeon-16x32.png" width="80" height="64"/>
 <tile id="0">
  <properties>
   <property name="light-color" type="color" value="#ffae6b2b"/>
  </properties>
  <animation>
   <frame tileid="1" duration="150"/>
   <frame tileid="0" duration="150"/>
   <frame tileid="2" duration="150"/>
   <frame tileid="3" duration="150"/>
   <frame tileid="4" duration="150"/>
  </animation>
 </tile>
 <tile id="1" type="light">
  <properties>
   <property name="name" value="fire"/>
  </properties>
 </tile>
 <tile id="5">
  <properties>
   <property name="light-color" type="color" value="#ff3aaf2e"/>
  </properties>
  <animation>
   <frame tileid="6" duration="150"/>
   <frame tileid="5" duration="150"/>
   <frame tileid="7" duration="150"/>
   <frame tileid="8" duration="150"/>
   <frame tileid="9" duration="150"/>
  </animation>
 </tile>
</tileset>
