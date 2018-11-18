<?xml version="1.0" encoding="UTF-8"?>
<tileset name="roguelike-16x16" tilewidth="16" tileheight="16" spacing="1" tilecount="1938" columns="57">
 <image source="roguelike-16x16-anim.png" width="968" height="577"/>
 <terraintypes>
  <terrain name="water" tile="1"/>
  <terrain name="path-dark" tile="578"/>
  <terrain name="path-light" tile="1262"/>
  <terrain name="path-gravel" tile="920"/>
  <terrain name="grass-edge" tile="914"/>
 </terraintypes>
 <tile id="0" probability="0.5">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="1" probability="0.5">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="2" terrain=",,,0"/>
 <tile id="3" terrain=",,0,0">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="4" terrain=",,0,">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="5" probability="0.5">
  <properties>
   <property name="type" value="grass"/>
  </properties>
 </tile>
 <tile id="6" probability="0.5">
  <properties>
   <property name="type" value="dirt"/>
  </properties>
 </tile>
 <tile id="7">
  <properties>
   <property name="type" value="gravel"/>
  </properties>
 </tile>
 <tile id="8">
  <properties>
   <property name="type" value="dirt"/>
  </properties>
 </tile>
 <tile id="13" type="fire">
  <animation>
   <frame tileid="13" duration="200"/>
   <frame tileid="14" duration="200"/>
  </animation>
 </tile>
 <tile id="57" terrain="0,0,0,">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="58" terrain="0,0,,0">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="59" terrain=",0,,0">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="60" terrain="0,0,0,0">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="61" terrain="0,,0,">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="62" probability="0.5">
  <properties>
   <property name="type" value="grass"/>
  </properties>
 </tile>
 <tile id="63" probability="0.5">
  <properties>
   <property name="type" value="dirt"/>
  </properties>
 </tile>
 <tile id="64">
  <properties>
   <property name="type" value="gravel"/>
  </properties>
 </tile>
 <tile id="65">
  <properties>
   <property name="type" value="dirt"/>
  </properties>
 </tile>
 <tile id="114" terrain="0,,0,0">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="115" terrain=",0,0,0">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="116" terrain=",0,,">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="117" terrain="0,0,,">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="118" terrain="0,,,">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="171">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="172">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="173">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="174">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="175">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="228">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="229">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="230">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="231" probability="0.5">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="232">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="287">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="288">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="289">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="396" type="fire">
  <animation>
   <frame tileid="396" duration="200"/>
   <frame tileid="397" duration="200"/>
  </animation>
 </tile>
 <tile id="416">
  <animation>
   <frame tileid="416" duration="175"/>
   <frame tileid="417" duration="175"/>
  </animation>
 </tile>
 <tile id="453">
  <animation>
   <frame tileid="453" duration="200"/>
   <frame tileid="454" duration="200"/>
  </animation>
 </tile>
 <tile id="470" type="fire">
  <animation>
   <frame tileid="470" duration="200"/>
   <frame tileid="471" duration="200"/>
  </animation>
 </tile>
 <tile id="473">
  <animation>
   <frame tileid="473" duration="175"/>
   <frame tileid="474" duration="175"/>
  </animation>
 </tile>
 <tile id="510" type="fire">
  <animation>
   <frame tileid="510" duration="200"/>
   <frame tileid="511" duration="200"/>
  </animation>
 </tile>
 <tile id="518" terrain="1,1,1,"/>
 <tile id="519" terrain="1,1,,1"/>
 <tile id="520" terrain=",,,1"/>
 <tile id="521" terrain=",,1,1"/>
 <tile id="522" terrain=",,1,"/>
 <tile id="526">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="527">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="528">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="529">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="530">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="531">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="541" type="flower">
  <animation>
   <frame tileid="1795" duration="350"/>
   <frame tileid="541" duration="350"/>
   <frame tileid="1852" duration="350"/>
  </animation>
 </tile>
 <tile id="542" type="flower">
  <animation>
   <frame tileid="1796" duration="350"/>
   <frame tileid="542" duration="350"/>
   <frame tileid="1853" duration="350"/>
  </animation>
 </tile>
 <tile id="543" type="flower">
  <animation>
   <frame tileid="1797" duration="350"/>
   <frame tileid="543" duration="350"/>
   <frame tileid="1854" duration="350"/>
  </animation>
 </tile>
 <tile id="544" type="flower">
  <animation>
   <frame tileid="1798" duration="350"/>
   <frame tileid="544" duration="350"/>
   <frame tileid="1855" duration="350"/>
  </animation>
 </tile>
 <tile id="567">
  <animation>
   <frame tileid="567" duration="200"/>
   <frame tileid="568" duration="200"/>
  </animation>
 </tile>
 <tile id="575" terrain="1,,1,1"/>
 <tile id="576" terrain=",1,1,1"/>
 <tile id="577" terrain=",1,,1"/>
 <tile id="578" terrain="1,1,1,1"/>
 <tile id="579" terrain="1,,1,"/>
 <tile id="624" type="fire">
  <animation>
   <frame tileid="624" duration="200"/>
   <frame tileid="625" duration="200"/>
  </animation>
 </tile>
 <tile id="634" terrain=",1,,"/>
 <tile id="635" terrain="1,1,,"/>
 <tile id="636" terrain="1,,,"/>
 <tile id="640">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="641">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="642">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="643">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="644">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="645">
  <properties>
   <property name="tree" value="true"/>
  </properties>
 </tile>
 <tile id="855" terrain="4,4,4,"/>
 <tile id="856" terrain="4,4,,4"/>
 <tile id="857" terrain=",,,4"/>
 <tile id="858" terrain=",,4,4"/>
 <tile id="859" terrain=",,4,"/>
 <tile id="860" terrain="3,3,3,"/>
 <tile id="861" terrain="3,3,,3"/>
 <tile id="862" terrain=",,,3"/>
 <tile id="863" terrain=",,3,3"/>
 <tile id="864" terrain=",,3,"/>
 <tile id="912" terrain="4,,4,4"/>
 <tile id="913" terrain=",4,4,4"/>
 <tile id="914" terrain=",4,,4"/>
 <tile id="915" terrain="4,4,4,4"/>
 <tile id="916" terrain="4,,4,"/>
 <tile id="917" terrain="3,,3,3"/>
 <tile id="918" terrain=",3,3,3"/>
 <tile id="919" terrain=",3,,3"/>
 <tile id="920" terrain="3,3,3,3"/>
 <tile id="921" terrain="3,,3,"/>
 <tile id="971" terrain=",4,,"/>
 <tile id="972" terrain="4,4,,"/>
 <tile id="973" terrain="4,,,"/>
 <tile id="976" terrain=",3,,"/>
 <tile id="977" terrain="3,3,,"/>
 <tile id="978" terrain="3,,,"/>
 <tile id="1119">
  <properties>
   <property name="emitter_smoke" value="1"/>
  </properties>
 </tile>
 <tile id="1136">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1137">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1138">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1139">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1176">
  <properties>
   <property name="emitter_smoke" value="1.0"/>
  </properties>
 </tile>
 <tile id="1193">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1194">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1195">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1196">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1202" terrain="2,2,2,"/>
 <tile id="1203" terrain="2,2,,2"/>
 <tile id="1204" terrain=",,,2"/>
 <tile id="1205" terrain=",,2,2"/>
 <tile id="1206" terrain=",,2,"/>
 <tile id="1250">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1251">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1252">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1253">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1259" terrain="2,,2,2"/>
 <tile id="1260" terrain=",2,2,2"/>
 <tile id="1261" terrain=",2,,2"/>
 <tile id="1262" terrain="2,2,2,2"/>
 <tile id="1263" terrain="2,,2,"/>
 <tile id="1307">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1308">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1309">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1310">
  <properties>
   <property name="wall" value="true"/>
  </properties>
 </tile>
 <tile id="1318" terrain=",2,,"/>
 <tile id="1319" terrain="2,2,,"/>
 <tile id="1320" terrain="2,,,"/>
 <tile id="1365">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="1366">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="1367">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="1422">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="1423">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="1424">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="1767">
  <properties>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" type="float" value="1"/>
  </properties>
 </tile>
 <tile id="1768">
  <properties>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" type="float" value="1"/>
  </properties>
 </tile>
 <tile id="1769">
  <properties>
   <property name="walkable" type="bool" value="true"/>
   <property name="weight" type="float" value="200"/>
  </properties>
 </tile>
</tileset>
