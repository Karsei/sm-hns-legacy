SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

CREATE TABLE IF NOT EXISTS `hns_modellist` (
  `idnum` int(6) NOT NULL auto_increment,
  `modelpath` varchar(256) NOT NULL default '',
  `heightfix` varchar(64) NOT NULL default 'no',
  `usemoney` varchar(64) NOT NULL default 'no',
  `langnamedata` varchar(512) NOT NULL default '',
  PRIMARY KEY (`idnum`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;