<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.2" tiledversion="1.2.0" name="dungeon-16x16" tilewidth="16" tileheight="16" tilecount="552" columns="23">
 <properties>
  <property name="spritesheet" value="User/dungeon-red-16x16.png"/>
 </properties>
 <image source="dungeon-16x16.png" width="368" height="384"/>
 <terraintypes>
  <terrain name="Water" tile="39"/>
  <terrain name="Stone" tile="48"/>
 </terraintypes>
 <tile id="1" terrain=",,1,1">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="2" terrain=",,1,1">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="3" terrain=",,1,1">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="4">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="11">
  <properties>
   <property name="type" value="stairs"/>
  </properties>
 </tile>
 <tile id="12">
  <properties>
   <property name="type" value="stairs"/>
  </properties>
 </tile>
 <tile id="15" terrain=",,,0"/>
 <tile id="16" terrain=",,0,0"/>
 <tile id="17" terrain=",,0,"/>
 <tile id="19" terrain="0,0,0,"/>
 <tile id="21" terrain="0,0,,0"/>
 <tile id="23" terrain=",1,,1">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="24" type="blank-floor" probability="0.5">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="25" type="blank-floor" probability="0.5">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="26" type="blank-floor" probability="0.1">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="27" terrain="1,,1,">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="34" terrain="1,1,1,"/>
 <tile id="35" terrain="1,1,,1"/>
 <tile id="36">
  <properties>
   <property name="type" value="stairs"/>
  </properties>
 </tile>
 <tile id="38" terrain=",0,,0"/>
 <tile id="39" terrain="0,0,0,0"/>
 <tile id="40" terrain="0,,0,"/>
 <tile id="46" terrain=",1,,1">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="47" type="blank-floor" probability="0.5">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="48" type="blank-floor" terrain="1,1,1,1" probability="0.5">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="49" type="blank-floor" probability="0.5">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="50" terrain="1,,1,">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="57" terrain="1,,1,1"/>
 <tile id="58" terrain=",1,1,1"/>
 <tile id="59">
  <properties>
   <property name="type" value="stairs"/>
  </properties>
 </tile>
 <tile id="61" terrain=",0,,"/>
 <tile id="62" terrain="0,0,,"/>
 <tile id="63" terrain="0,,,"/>
 <tile id="65" terrain="0,,0,0"/>
 <tile id="67" terrain=",0,0,0"/>
 <tile id="69" terrain=",1,,1">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="70" type="blank-floor" probability="0.5">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="71" type="blank-floor" probability="0.5">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="72" type="blank-floor" probability="0.5">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="73" terrain="1,,1,">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="81" type="crate"/>
 <tile id="92">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="93" terrain="1,1,,">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="94" terrain="1,1,,">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="95" terrain="1,1,,">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="96">
  <properties>
   <property name="weight" type="float" value="0.5"/>
  </properties>
 </tile>
 <tile id="102" type="chest">
  <properties>
   <property name="breakable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="104" type="crate">
  <properties>
   <property name="breakable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="148" type="bridge">
  <properties>
   <property name="breakable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="150" type="crate">
  <properties>
   <property name="breakable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="151">
  <properties>
   <property name="breakable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="184" terrain=",,,1"/>
 <tile id="185" terrain=",,1,1"/>
 <tile id="186" terrain=",,1,"/>
 <tile id="194" type="bridge">
  <properties>
   <property name="breakable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="207" terrain=",1,,"/>
 <tile id="208" terrain="1,1,,"/>
 <tile id="209" terrain="1,,,"/>
 <tile id="238" type="empty"/>
 <tile id="271" type="waterfall">
  <properties>
   <property name="name" value="waterfall"/>
  </properties>
  <animation>
   <frame tileid="271" duration="150"/>
   <frame tileid="272" duration="150"/>
   <frame tileid="273" duration="150"/>
  </animation>
 </tile>
 <tile id="283" type="door">
  <properties>
   <property name="isDoor" type="bool" value="true"/>
   <property name="weight" type="float" value="1"/>
  </properties>
 </tile>
 <tile id="284" type="door">
  <properties>
   <property name="isDoor" type="bool" value="true"/>
   <property name="weight" type="float" value="1"/>
  </properties>
 </tile>
 <tile id="285" type="door">
  <properties>
   <property name="isDoor" type="bool" value="true"/>
   <property name="weight" type="float" value="1"/>
  </properties>
 </tile>
 <tile id="340">
  <properties>
   <property name="obstacle" type="bool" value="false"/>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" type="float" value="1"/>
  </properties>
 </tile>
 <tile id="341">
  <properties>
   <property name="obstacle" type="bool" value="false"/>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" type="float" value="500"/>
  </properties>
 </tile>
 <tile id="342">
  <properties>
   <property name="obstacle" type="bool" value="false"/>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" type="float" value="250"/>
  </properties>
 </tile>
 <tile id="363">
  <properties>
   <property name="obstacle" type="bool" value="false"/>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" type="float" value="-1000"/>
  </properties>
 </tile>
</tileset>
