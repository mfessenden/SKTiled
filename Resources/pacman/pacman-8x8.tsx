<?xml version="1.0" encoding="UTF-8"?>
<tileset name="maze-8x8" tilewidth="8" tileheight="8" spacing="1" tilecount="176" columns="22">
 <properties>
  <property name="walkable" value="34,37,56,59,78,81"/>
 </properties>
 <image source="pm-maze-8x8.png" trans="800080" width="197" height="71"/>
 <tile id="4">
  <properties>
   <property name="isDynamic" type="bool" value="true"/>
  </properties>
 </tile>
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
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" value="10"/>
  </properties>
 </tile>
 <tile id="37">
  <properties>
   <property name="speed" value="1"/>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" value="500"/>
  </properties>
 </tile>
 <tile id="53" type="Pellet">
  <objectgroup draworder="index">
   <object id="1" x="2" y="2" width="4" height="4"/>
  </objectgroup>
  <animation>
   <frame tileid="53" duration="250"/>
   <frame tileid="76" duration="250"/>
  </animation>
 </tile>
 <tile id="56">
  <properties>
   <property name="speed" value="1"/>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" value="2"/>
  </properties>
 </tile>
 <tile id="59">
  <properties>
   <property name="speed" value="0.4"/>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" value="1"/>
  </properties>
 </tile>
 <tile id="75" type="Dot">
  <objectgroup draworder="index">
   <object id="1" x="3" y="3" width="2" height="2"/>
  </objectgroup>
 </tile>
 <tile id="78">
  <properties>
   <property name="speed" value="1"/>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" value="1"/>
  </properties>
 </tile>
 <tile id="81">
  <properties>
   <property name="speed" value="1"/>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" value="-50"/>
  </properties>
 </tile>
</tileset>
