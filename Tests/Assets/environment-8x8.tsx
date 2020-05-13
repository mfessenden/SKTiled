<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.2" tiledversion="1.3.4" name="environment-8x8" tilewidth="8" tileheight="8" tilecount="45" columns="15">
 <image source="environment-8x8.png" width="120" height="24"/>
 <tile id="0" type="wall" probability="0.25"/>
 <tile id="1" type="wall" probability="0.25"/>
 <tile id="2" type="wall" probability="0.05"/>
 <tile id="3" type="wall" probability="0.075"/>
 <tile id="5" type="door">
  <properties>
   <property name="isDoor" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="6" type="stairs">
  <properties>
   <property name="object" value="stairs"/>
  </properties>
 </tile>
 <tile id="7" type="wall" probability="0.25"/>
 <tile id="8" type="wall" probability="0.25"/>
 <tile id="9" type="wall" probability="0.05">
  <properties>
   <property name="lightColor" type="color" value="#ffffff64"/>
  </properties>
 </tile>
 <tile id="10" type="wall" probability="0.075"/>
 <tile id="12" type="door">
  <properties>
   <property name="isDoor" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="13" type="stairs">
  <properties>
   <property name="object" value="stairs"/>
  </properties>
 </tile>
 <tile id="14" type="tree"/>
 <tile id="15" type="wall" probability="0.25"/>
 <tile id="16" type="floor" probability="0.3"/>
 <tile id="17" type="floor" probability="0.3"/>
 <tile id="19" type="floor"/>
 <tile id="20" type="trapdoor">
  <properties>
   <property name="object" value="hole"/>
  </properties>
 </tile>
 <tile id="21" type="stairs">
  <properties>
   <property name="object" value="stairs"/>
  </properties>
 </tile>
 <tile id="22" type="wall" probability="0.25"/>
 <tile id="23" type="floor" probability="0.3"/>
 <tile id="24" type="floor" probability="0.3"/>
 <tile id="26" type="floor"/>
 <tile id="27" type="trapdoor">
  <properties>
   <property name="object" value="hole"/>
  </properties>
 </tile>
 <tile id="28" type="stairs">
  <properties>
   <property name="object" value="stairs"/>
  </properties>
 </tile>
 <tile id="29" type="tree"/>
 <tile id="30" type="wall" probability="0.25"/>
 <tile id="31" type="floor" probability="0.3"/>
 <tile id="37" type="wall" probability="0.25"/>
 <tile id="38" type="floor" probability="0.3"/>
 <tile id="43" type="floor"/>
</tileset>
