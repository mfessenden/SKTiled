<?xml version="1.0" encoding="UTF-8"?>
<tileset name="pacman-8x8" tilewidth="8" tileheight="8" spacing="1" tilecount="176" columns="22">
 <properties>
  <property name="atlas" value="Mazes-8x8"/>
 </properties>
 <image source="pacman-8x8.png" trans="800080" width="197" height="71"/>
 <tile id="12">
  <properties>
   <property name="speed" value="0"/>
   <property name="weight" value="0"/>
  </properties>
 </tile>
 <tile id="15">
  <properties>
   <property name="speed" value="0"/>
   <property name="weight" value="0"/>
  </properties>
 </tile>
 <tile id="34">
  <properties>
   <property name="speed" value="1"/>
   <property name="weight" value="10"/>
  </properties>
 </tile>
 <tile id="37">
  <properties>
   <property name="speed" value="1"/>
   <property name="weight" value="100"/>
  </properties>
 </tile>
 <tile id="53">
  <properties>
   <property name="type" value="pellet"/>
   <property name="collisionSize" type="float" value="4.0"/>
  </properties>
  <animation>
   <frame tileid="53" duration="250"/>
   <frame tileid="76" duration="250"/>
  </animation>
 </tile>
 <tile id="56">
  <properties>
   <property name="speed" value="1"/>
   <property name="weight" value="-10"/>
  </properties>
 </tile>
 <tile id="59">
  <properties>
   <property name="speed" value="0.4"/>
   <property name="weight" value="1"/>
  </properties>
 </tile>
 <tile id="75">
  <properties>
   <property name="type" value="dot"/>
   <property name="collisionSize" type="float" value="2.0"/>
  </properties>
 </tile>
 <tile id="78">
  <properties>
   <property name="speed" value="1"/>
   <property name="weight" value="1"/>
  </properties>
 </tile>
 <tile id="81">
  <properties>
   <property name="speed" value="1"/>
   <property name="weight" value="25"/>
  </properties>
 </tile>
</tileset>