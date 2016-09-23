<?xml version="1.0" encoding="UTF-8"?>
<tileset name="cc-bg-tiles" tilewidth="16" tileheight="16" spacing="1" tilecount="1938" columns="57">
    <image source="roguelike-16x16-anim.png" width="968" height="577"/>
    <terraintypes>
        <terrain name="water" tile="1"/>
        <terrain name="path-dark" tile="578"/>
        <terrain name="path-light" tile="1262"/>
    </terraintypes>
    <tile id="0" terrain="0,0,0,0" probability="0.5">
        <properties>
            <property name="waterLevel" value="1.0"/>
        </properties>
    </tile>
    <tile id="1" terrain="0,0,0,0" probability="0.5">
        <properties>
            <property name="waterLevel" value="1.0"/>
        </properties>
    </tile>
    <tile id="2" terrain=",,,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="3" terrain=",,0,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="4" terrain=",,0,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="5" probability="0.5">
        <properties>
            <property name="groundType" value="grass"/>
        </properties>
    </tile>
    <tile id="6" probability="0.5">
        <properties>
            <property name="groundType" value="dirt"/>
        </properties>
    </tile>
    <tile id="7">
        <properties>
            <property name="groundType" value="gravel"/>
        </properties>
    </tile>
    <tile id="8">
        <properties>
            <property name="groundType" value="dirt"/>
        </properties>
    </tile>
    <tile id="13">
        <animation>
            <frame tileid="13" duration="100"/>
            <frame tileid="14" duration="100"/>
        </animation>
    </tile>
    <tile id="57" terrain="0,0,0,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="58" terrain="0,0,,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="59" terrain=",0,,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="60" terrain="0,0,0,0">
        <properties>
            <property name="waterLevel" value="1.0"/>
        </properties>
    </tile>
    <tile id="61" terrain="0,,0,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="62" probability="0.5">
        <properties>
            <property name="groundType" value="grass"/>
        </properties>
    </tile>
    <tile id="63" probability="0.5">
        <properties>
            <property name="groundType" value="dirt"/>
        </properties>
    </tile>
    <tile id="64">
        <properties>
            <property name="groundType" value="gravel"/>
        </properties>
    </tile>
    <tile id="65">
        <properties>
            <property name="groundType" value="dirt"/>
        </properties>
    </tile>
    <tile id="114" terrain="0,,0,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="115" terrain=",0,0,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="116" terrain=",0,,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="117" terrain="0,0,,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="118" terrain="0,,,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="171" terrain="0,0,0,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="172" terrain="0,0,,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="173" terrain=",,,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="174" terrain=",,0,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="175" terrain=",,0,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="228" terrain="0,,0,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="229" terrain=",0,0,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="230" terrain=",0,,0">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="231" terrain="0,0,0,0" probability="0.5">
        <properties>
            <property name="waterLevel" value="1.0"/>
        </properties>
    </tile>
    <tile id="232" terrain="0,,0,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="287" terrain=",0,,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="288" terrain="0,0,,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="289" terrain="0,,,">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="396">
        <animation>
            <frame tileid="396" duration="100"/>
            <frame tileid="397" duration="100"/>
        </animation>
    </tile>
    <tile id="406" terrain="1,1,1,"/>
    <tile id="407" terrain="1,1,,1"/>
    <tile id="416">
        <animation>
            <frame tileid="416" duration="100"/>
            <frame tileid="417" duration="100"/>
        </animation>
    </tile>
    <tile id="453">
        <animation>
            <frame tileid="453" duration="100"/>
            <frame tileid="454" duration="100"/>
        </animation>
    </tile>
    <tile id="463" terrain="1,,1,1"/>
    <tile id="464" terrain=",1,1,1"/>
    <tile id="470">
        <animation>
            <frame tileid="470" duration="200"/>
            <frame tileid="471" duration="200"/>
        </animation>
    </tile>
    <tile id="473">
        <animation>
            <frame tileid="473" duration="100"/>
            <frame tileid="474" duration="100"/>
        </animation>
    </tile>
    <tile id="510">
        <animation>
            <frame tileid="510" duration="100"/>
            <frame tileid="511" duration="100"/>
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
    <tile id="541">
        <animation>
            <frame tileid="1795" duration="350"/>
            <frame tileid="541" duration="350"/>
            <frame tileid="1852" duration="350"/>
        </animation>
    </tile>
    <tile id="542">
        <animation>
            <frame tileid="1796" duration="350"/>
            <frame tileid="542" duration="350"/>
            <frame tileid="1853" duration="350"/>
        </animation>
    </tile>
    <tile id="543">
        <animation>
            <frame tileid="1797" duration="350"/>
            <frame tileid="543" duration="350"/>
            <frame tileid="1854" duration="350"/>
        </animation>
    </tile>
    <tile id="544">
        <animation>
            <frame tileid="1798" duration="350"/>
            <frame tileid="544" duration="350"/>
            <frame tileid="1855" duration="350"/>
        </animation>
    </tile>
    <tile id="567">
        <animation>
            <frame tileid="567" duration="100"/>
            <frame tileid="568" duration="100"/>
        </animation>
    </tile>
    <tile id="575" terrain="1,,1,1"/>
    <tile id="576" terrain=",1,1,1"/>
    <tile id="577" terrain=",1,,1"/>
    <tile id="578" terrain="1,1,1,1"/>
    <tile id="579" terrain="1,,1,"/>
    <tile id="624">
        <animation>
            <frame tileid="510" duration="100"/>
            <frame tileid="511" duration="100"/>
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
    <tile id="1090" terrain="2,2,2,"/>
    <tile id="1091" terrain="2,2,,2"/>
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
    <tile id="1147" terrain="2,,2,2"/>
    <tile id="1148" terrain=",2,2,2"/>
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
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="1366">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="1367">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="1422">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="1423">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
    <tile id="1424">
        <properties>
            <property name="waterLevel" value="0.5"/>
        </properties>
    </tile>
</tileset>
