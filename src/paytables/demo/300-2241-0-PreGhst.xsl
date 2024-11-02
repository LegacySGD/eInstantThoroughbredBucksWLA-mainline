<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var scenarioPrizes = getPrizesData(scenario);
						var scenarioMainGame = getMainGameData(scenario);
						var scenarioBonusGame = getBonusGameData(scenario);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var prizeNames = (prizeNamesDesc.substring(1)).split(','); 

						////////////////////
						// Parse scenario //
						////////////////////

						const bonusSymbQty  = 5;
						const bonusTurnsQty = 10;
						const bonusPrizesPerTurn = 3;
						const racerQty      = 8;
						const racerTurnsQty = 6;
						const racerMovesQty = 4;
						const raceWinPos    = 12;

						var doBonusGame = false;

						var arrMoveData      = [];
						var arrRaceData      = [];
						var arrScenarioMoves = [];
						var arrScenarioTurns = [];
						var arrTurnData      = [];
						var objRacerMove     = {};						

						for (var racerIndex = 0; racerIndex < racerQty; racerIndex++)
						{
							arrScenarioTurns = scenarioMainGame[racerIndex].split(",");

							arrTurnData = [];

							for (var racerTurnIndex = 0; racerTurnIndex < racerTurnsQty; racerTurnIndex++)
							{
								arrScenarioMoves = arrScenarioTurns[racerTurnIndex].match(new RegExp('.{3}', 'g'));
								
								arrMoveData = [];

								for (var racerMoveIndex = 0; racerMoveIndex < racerMovesQty; racerMoveIndex++)
								{
									objRacerMove = {iPosition: -1, strEvent: ''};

									objRacerMove.iPosition = parseInt(arrScenarioMoves[racerMoveIndex].substr(0,2), 10);
									objRacerMove.strEvent  = arrScenarioMoves[racerMoveIndex][2];

									arrMoveData.push(objRacerMove);
								}

								arrTurnData.push(arrMoveData);
							}

							arrRaceData.push(arrTurnData);
						}

						///////////////////////
						// Output Game Parts //
						///////////////////////

						const symbEvents = 'mbr';
						const symbIWs    = 'vwxyz';
						const doRotate   = true;
						const doTitle    = true;

						const cellHeight    = 24;
						const cellWidth     = 96;
						const cellWidthKey  = 24;
						const cellMargin    = 1;
						const cellTextY     = 15;
						const cellBonusHeight = 72;
						const colourBlack   = '#000000';
						const colourBlue    = '#99ccff';
						const colourGreen   = '#00cc00';
						const colourLemon   = '#ffff99';
						const colourLilac   = '#ccccff';
						const colourLime    = '#ccff99';
						const colourOrange  = '#ffcc99';
						const colourPink    = '#ffccff';
						const colourRed     = '#ff9999';
						const colourWhite   = '#ffffff';

						const eventColours = [colourLilac, colourPink, colourGreen];
						const iwColours    = [colourRed, colourOrange, colourLemon, colourLime, colourBlue];

						var r = [];

						var boxColourStr = '';
						var canvasIdStr  = '';
						var elementStr   = '';
						var symbEvent    = '';
						var symbIW       = '';

						function showSymb(A_strCanvasId, A_strCanvasElement, A_iBoxWidth, A_strBoxColour, A_strText, A_doRotate, A_doTitle)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasWidth  = (A_doRotate) ? cellHeight + 2 * cellMargin : A_iBoxWidth + 2 * cellMargin;
							var canvasHeight = (A_doRotate) ? A_iBoxWidth + 2 * cellMargin : cellHeight + 2 * cellMargin;
							var textColour   = (A_doTitle) ? colourWhite : colourBlack;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							if (A_doRotate)
							{
								r.push(canvasCtxStr + '.translate(0,' + (A_iBoxWidth + 3).toString() + ');');
								r.push(canvasCtxStr + '.rotate(-Math.PI / 2);');
							}

							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + A_iBoxWidth.toString() + ', ' + cellHeight.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (A_iBoxWidth - 2).toString() + ', ' + (cellHeight - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + textColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (A_iBoxWidth / 2 + cellMargin).toString() + ', ' + cellTextY.toString() + ');');

							r.push('</script>');
						}

						///////////////
						// Event Key //
						///////////////

						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleEventKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var eventIndex = 0; eventIndex < symbEvents.length; eventIndex++)
						{
							symbEvent    = symbEvents[eventIndex];
							canvasIdStr  = 'cvsKeySymb' + symbEvent;
							elementStr   = 'eleKeySymb' + symbEvent;
							boxColourStr = eventColours[eventIndex];
							symbDesc     = 'symb' + symbEvent.toUpperCase();

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, cellWidthKey, boxColourStr, '#', !doRotate, !doTitle);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						//////////////////
						// IW Prize Key //
						//////////////////

						r.push('<div style="float:left">');
						r.push('<p>' + getTranslationByName("titleInstantWinPrizeKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var iwIndex = 0; iwIndex < symbIWs.length; iwIndex++)
						{
							symbIW       = symbIWs[iwIndex];
							canvasIdStr  = 'cvsKeySymb' + symbIW;
							elementStr   = 'eleKeySymb' + symbIW;
							boxColourStr = iwColours[iwIndex];
							symbDesc     = 'symb' + symbIW.toUpperCase();

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, cellWidthKey, boxColourStr, '#', !doRotate, !doTitle);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						///////////////
						// Main Game //
						///////////////

						var cellStr    = '';
						var multiVal   = 0;
						var prizeText  = '';
						var doWinPrize = false;

						function showGridMoves(A_strCanvasId, A_strCanvasElement, A_arrGrid, A_iTurn)
						{
							var gridCanvasWidth  = cellWidth + 2 * cellMargin;
							var gridCanvasHeight = cellWidth + 2 * cellMargin;

							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var cellY        = 0;
							var isEventCell  = false;
							var isIWCell     = false;
							var isWinner     = false;
							var objCell      = {};
							var symbIndex    = -1;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasWidth.toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var moveIndex = 0; moveIndex < racerMovesQty; moveIndex++)
							{
								objCell      = A_arrGrid[A_iTurn][moveIndex];
								isEventCell  = (symbEvents.indexOf(objCell.strEvent) != -1);
								isIWCell     = (symbIWs.indexOf(objCell.strEvent) != -1);
								isWinner     = (A_iTurn == racerTurnsQty-1 && moveIndex == racerMovesQty-1 && objCell.iPosition == raceWinPos);
								symbIndex    = (isEventCell) ? symbEvents.indexOf(objCell.strEvent) : ((isIWCell) ? symbIWs.indexOf(objCell.strEvent) : -1);
								boxColourStr = (isEventCell) ? eventColours[symbIndex] : ((isIWCell) ? iwColours[symbIndex] : ((isWinner) ? colourGreen : colourWhite));
								cellY        = (racerMovesQty - moveIndex - 1) * cellHeight;

								r.push(canvasCtxStr + '.font = "bold 14px Arial";');
								r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellWidth.toString() + ', ' + cellHeight.toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
								r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellWidth - 2).toString() + ', ' + (cellHeight - 2).toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
								r.push(canvasCtxStr + '.fillText("' + objCell.iPosition.toString() + '", ' + (cellWidth / 2 + cellMargin).toString() + ', ' + (cellY + cellTextY).toString() + ');');
							}

							r.push('</script>');
						}

						r.push('<p style="clear:both"><br>' + getTranslationByName("mainGame", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						//////////////////////
						// Main Game Racers //
						//////////////////////

						r.push('<tr class="tablebody">');
						r.push('<td>&nbsp;</td>');

						for (var racerIndex = 0; racerIndex < racerQty; racerIndex++)
						{
							canvasIdStr = 'cvsTitleRacer' + racerIndex.toString();
							elementStr  = 'eleTitleRacer' + racerIndex.toString();
							cellStr     = getTranslationByName("titleRacer", translations) + ' ' + (racerIndex+1).toString();

							r.push('<td>');

							showSymb(canvasIdStr, elementStr, cellWidth, colourBlack, cellStr, !doRotate, doTitle);

							r.push('</td>');
						}

						r.push('</tr>');

						//////////////////////
						// Main Game Prizes //
						//////////////////////

						r.push('<tr class="tablebody">');
						r.push('<td>');
						
						showSymb('cvsTitlePrize', 'eleTitlePrize', cellWidth, colourBlack, getTranslationByName("titlePrize", translations), !doRotate, doTitle);

						r.push('</td>');

						for (var racerIndex = 0; racerIndex < racerQty; racerIndex++)
						{
							canvasIdStr  = 'cvsCellPrize' + racerIndex.toString();
							elementStr   = 'eleCellPrize' + racerIndex.toString();
							doWinPrize   = (arrRaceData[racerIndex][racerTurnsQty-1][racerMovesQty-1].iPosition == raceWinPos);
							boxColourStr = (doWinPrize) ? colourGreen : colourWhite;
							prizeText    = scenarioPrizes[racerIndex];
							cellStr      = (prizeText == 'X') ? '-' : convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)];

							r.push('<td>');

							showSymb(canvasIdStr, elementStr, cellWidth, boxColourStr, cellStr, !doRotate, !doTitle);

							r.push('</td>');
						}

						r.push('</tr>');

						//////////////////////
						// Main Game Multis //
						//////////////////////

						r.push('<tr class="tablebody">');
						r.push('<td>');
						
						showSymb('cvsTitleMulti', 'eleTitleMulti', cellWidth, colourBlack, getTranslationByName("titleMulti", translations), !doRotate, doTitle);

						r.push('</td>');

						for (var racerIndex = 0; racerIndex < racerQty; racerIndex++)
						{
							canvasIdStr  = 'cvsCellMulti' + racerIndex.toString();
							elementStr   = 'eleCellMulti' + racerIndex.toString();
							doWinPrize   = (arrRaceData[racerIndex][racerTurnsQty-1][racerMovesQty-1].iPosition == raceWinPos);
							boxColourStr = (doWinPrize) ? colourGreen : colourWhite;
							multiVal     = 1;

							for (var turnIndex = 0; turnIndex < racerTurnsQty; turnIndex++)
							{
								for (var moveIndex = 0; moveIndex < racerMovesQty; moveIndex++)
								{
									if (arrRaceData[racerIndex][turnIndex][moveIndex].strEvent == 'm')
									{
										multiVal *= 2;
									}
								}
							}

							cellStr = multiVal.toString() + 'x';

							r.push('<td>');

							showSymb(canvasIdStr, elementStr, cellWidth, boxColourStr, cellStr, !doRotate, !doTitle);

							r.push('</td>');
						}

						r.push('</tr>');

						/////////////////////
						// Main Game Turns //
						/////////////////////

						for (var turnIndex = racerTurnsQty-1; turnIndex >= 0; turnIndex--)
						{
							r.push('<tr class="tablebody">');

							canvasIdStr = 'cvsTitleTurn' + turnIndex.toString();
							elementStr  = 'eleTitleTurn' + turnIndex.toString();
							cellStr     = getTranslationByName("titleTurn", translations) + ' ' + (turnIndex+1).toString();

							r.push('<td align="right">');

							showSymb(canvasIdStr, elementStr, cellWidth, colourBlack, cellStr, doRotate, doTitle);

							r.push('</td>');

							for (var racerIndex = 0; racerIndex < racerQty; racerIndex++)
							{
								canvasIdStr = 'cvsGridTurn' + turnIndex.toString() + '_' + racerIndex.toString();
								elementStr  = 'eleGridTurn' + turnIndex.toString() + '_' + racerIndex.toString();

								r.push('<td>');

								showGridMoves(canvasIdStr, elementStr, arrRaceData[racerIndex], turnIndex);

								r.push('</td>');
							}

							r.push('</tr>');
						}

						r.push('</table>');

						////////////////////
						// Main Game Wins //
						////////////////////

						var bonusQty  = 0;
						var bonusText = '';
						var objMove   = {};
						var winIW     = [];
						var winMulti  = 0;
						var winPrize  = '';
						var winRacer  = -1;

						for (var racerIndex = 0; racerIndex < racerQty; racerIndex++)
						{
							if (arrRaceData[racerIndex][racerTurnsQty-1][racerMovesQty-1].iPosition == raceWinPos)
							{
								winRacer = racerIndex;
								winPrize = scenarioPrizes[winRacer];								

								for (var turnIndex = 0; turnIndex < racerTurnsQty; turnIndex++)
								{
									for (var moveIndex = 0; moveIndex < racerMovesQty; moveIndex++)
									{
										if (arrRaceData[winRacer][turnIndex][moveIndex].strEvent == 'm')
										{
											winMulti++;
										}
									}
								}
							}

							for (var turnIndex = 0; turnIndex < racerTurnsQty; turnIndex++)
							{
								for (var moveIndex = 0; moveIndex < racerMovesQty; moveIndex++)
								{
									objMove = arrRaceData[racerIndex][turnIndex][moveIndex];

									if (objMove.strEvent == 'b')
									{
										bonusQty++;
									}
									else if (symbIWs.indexOf(objMove.strEvent) != -1)
									{
										winIW.push(objMove.strEvent);
									}
								}
							}
						}

						function getMultipliedPrize(A_strPrizeDesc, A_iMulti)
						{
							var bCurrSymbAtFront = false;
							var strCurrSymb      = '';
							var strDecSymb       = '';
							var strThouSymb      = '';

							function getPrizeInCents(AA_strPrize)
							{
								var strPrizeWithoutCurrency = AA_strPrize.replace(new RegExp('[^0-9., ]', 'g'), '');
								var iPos 					= AA_strPrize.indexOf(strPrizeWithoutCurrency);
								var iCurrSymbLength 		= AA_strPrize.length - strPrizeWithoutCurrency.length;
								var strPrizeWithoutDigits   = strPrizeWithoutCurrency.replace(new RegExp('[0-9]', 'g'), '');

								strDecSymb 		 = strPrizeWithoutCurrency.substr(-3,1);									
								bCurrSymbAtFront = (iPos != 0);									
								strCurrSymb 	 = (bCurrSymbAtFront) ? AA_strPrize.substr(0,iCurrSymbLength) : AA_strPrize.substr(-iCurrSymbLength);
								strThouSymb      = (strPrizeWithoutDigits.length > 1) ? strPrizeWithoutDigits[0] : strThouSymb;

								return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
							}

							function getCentsInCurr(AA_iPrize)
							{
								var strValue = AA_iPrize.toString();

								strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
								strValue = (strThouSymb != '') ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
								strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

								return strValue;
							}

							var strPrizeAmount = convertedPrizeValues[getPrizeNameIndex(prizeNames, A_strPrizeDesc)];

							var iPrize = getPrizeInCents(strPrizeAmount);
							var iTotal = iPrize * A_iMulti;

							return getCentsInCurr(iTotal);
						}

						r.push('<br><table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						if (winPrize != '' && winPrize != 'X')
						{
							canvasIdStr  = 'cvsWinMulti';
							elementStr   = 'eleWinMulti';
							boxColourStr = eventColours[symbEvents.indexOf('m')];
							multiVal     = Math.pow(2,winMulti);

							r.push('<tr class="tablebody">');
							r.push('<td>' + getTranslationByName("mainPrize", translations) + ' : ' +  winMulti.toString() + ' x</td>');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, cellWidthKey, boxColourStr, '#', !doRotate, !doTitle);

							r.push('</td>');
							r.push('<td>= ' + multiVal.toString() + ' x ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, winPrize)] + ' = ' + getMultipliedPrize(winPrize, multiVal) + '</td>');
							r.push('</tr>');
						}

						if (winIW.length != 0)
						{
							var iwIndex = 0;

							for (var iwWinIndex = 0; iwWinIndex < winIW.length; iwWinIndex++)
							{
								canvasIdStr  = 'cvsWinIW' + iwWinIndex.toString();
								elementStr   = 'eleWinIW' + iwWinIndex.toString();
								iwIndex      = symbIWs.indexOf(winIW[iwWinIndex]);
								boxColourStr = iwColours[iwIndex];
								winPrize     = 'IW' + (iwIndex + 1).toString();

								r.push('<tr class="tablebody">');
								r.push('<td>' + getTranslationByName("iwPrize", translations) + ' : ' + '</td>');
								r.push('<td align="center">');

								showSymb(canvasIdStr, elementStr, cellWidthKey, boxColourStr, '#', !doRotate, !doTitle);

								r.push('</td>');
								r.push('<td>= ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, winPrize)] + '</td>');
								r.push('</tr>');
							}
						}

						canvasIdStr  = 'cvsGotBonus';
						elementStr   = 'eleGotBonus';
						boxColourStr = eventColours[symbEvents.indexOf('b')];
						bonusText    = getTranslationByName("bonusCollected", translations) + ' ' + bonusQty.toString() + ' ' + getTranslationByName("bonusOf", translations) + ' ' + bonusSymbQty.toString();
						doBonusGame  = (bonusQty == bonusSymbQty);
						bonusText    += (doBonusGame) ? ' : ' + getTranslationByName("bonusGame", translations) + ' ' + getTranslationByName("bonusTriggered", translations) : '';

						r.push('<tr class="tablebody">');
						r.push('<td>' + getTranslationByName("mainBonusSymbs", translations) + ' : </td>');
						r.push('<td align="center">');

						showSymb(canvasIdStr, elementStr, cellWidthKey, boxColourStr, '#', !doRotate, !doTitle);

						r.push('</td>');
						r.push('<td>' + bonusText + '</td>');
						r.push('</tr>');

						r.push('</table>');

						////////////////
						// Bonus Game //
						////////////////

						if (doBonusGame)
						{
							function showBonusPrizes(A_strCanvasId, A_strCanvasElement, A_arrPrizes)
							{
								var gridCanvasWidth  = cellWidth + 2 * cellMargin;
								var gridCanvasHeight = cellBonusHeight + 2 * cellMargin;

								var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
								var cellY        = 0;
								var isMulti1     = false;
								var isMulti2     = false;
								var isPrize      = false;
								var symbIndex    = -1;
								var cellPrize    = '';
								var bonusText    = '';

								r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasWidth.toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
								r.push('<script>');
								r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
								r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
								r.push(canvasCtxStr + '.textAlign = "center";');
								r.push(canvasCtxStr + '.textBaseline = "middle";');

								for (var prizeIndex = 0; prizeIndex < bonusPrizesPerTurn; prizeIndex++)
								{
									cellPrize    = A_arrPrizes[prizeIndex];
									isMulti1     = (cellPrize == 'm1');
									isMulti2     = (cellPrize == 'm2');
									isPrize      = (cellPrize != undefined && cellPrize[0] == 'b');
									boxColourStr = (isMulti1) ? colourOrange : ((isMulti2) ? colourLemon : ((isPrize) ? colourRed : colourWhite));
									cellY        = prizeIndex * cellHeight;
									bonusText    = (isMulti1) ? getTranslationByName("bonusMulti", translations) + ' +1' : ((isMulti2) ? getTranslationByName("bonusMulti", translations) + ' +2' :
														((isPrize) ? convertedPrizeValues[getPrizeNameIndex(prizeNames, cellPrize.toUpperCase())] : ''));

									r.push(canvasCtxStr + '.font = "bold 14px Arial";');
									r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellWidth.toString() + ', ' + cellHeight.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellWidth - 2).toString() + ', ' + (cellHeight - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
									r.push(canvasCtxStr + '.fillText("' + bonusText + '", ' + (cellWidth / 2 + cellMargin).toString() + ', ' + (cellY + cellTextY).toString() + ');');
								}

								r.push('</script>');
							}

							function showBonusTotal(A_arrPrizes, A_iMulti)
							{
								var bCurrSymbAtFront = false;
								var iBonusTotal 	 = 0;
								var iPrize      	 = 0;
								var iPrizeTotal 	 = 0;
								var strCurrSymb      = '';
								var strDecSymb  	 = '';
								var strThouSymb      = '';

								function getPrizeInCents(AA_strPrize)
								{
									var strPrizeWithoutCurrency = AA_strPrize.replace(new RegExp('[^0-9., ]', 'g'), '');
									var iPos 					= AA_strPrize.indexOf(strPrizeWithoutCurrency);
									var iCurrSymbLength 		= AA_strPrize.length - strPrizeWithoutCurrency.length;
									var strPrizeWithoutDigits   = strPrizeWithoutCurrency.replace(new RegExp('[0-9]', 'g'), '');

									strDecSymb 		 = strPrizeWithoutCurrency.substr(-3,1);									
									bCurrSymbAtFront = (iPos != 0);									
									strCurrSymb 	 = (bCurrSymbAtFront) ? AA_strPrize.substr(0,iCurrSymbLength) : AA_strPrize.substr(-iCurrSymbLength);
									strThouSymb      = (strPrizeWithoutDigits.length > 1) ? strPrizeWithoutDigits[0] : strThouSymb;

									return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
								}

								function getCentsInCurr(AA_iPrize)
								{
									var strValue = AA_iPrize.toString();

									strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
									strValue = (strThouSymb != '') ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
									strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

									return strValue;
								}

								for (prizeIndex = 0; prizeIndex < A_arrPrizes.length; prizeIndex++)
								{
									iPrize = getPrizeInCents(A_arrPrizes[prizeIndex]);

									iPrizeTotal += iPrize;
								}

								iBonusTotal = iPrizeTotal * A_iMulti;

								r.push('<br>' + getTranslationByName("bonusPrize", translations) + ' : ' + getCentsInCurr(iPrizeTotal) + ' x ' + A_iMulti.toString() + ' = ' + getCentsInCurr(iBonusTotal));
							}

							r.push('<br><p>' + getTranslationByName("bonusGame", translations).toUpperCase() + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							//////////////////////
							// Bonus Game Turns //
							//////////////////////

							r.push('<tr class="tablebody">');
							r.push('<td>&nbsp;</td>');

							for (var turnIndex = 0; turnIndex < bonusTurnsQty; turnIndex++)
							{
								canvasIdStr = 'cvsTitleBonusTurn' + turnIndex.toString();
								elementStr  = 'eleTitleBonusTurn' + turnIndex.toString();
								cellStr     = getTranslationByName("titleBonusTurn", translations) + ' ' + (turnIndex+1).toString();

								r.push('<td>');

								showSymb(canvasIdStr, elementStr, cellWidth, colourBlack, cellStr, !doRotate, doTitle);

								r.push('</td>');
							}

							r.push('</tr>');
							r.push('<tr class="tablebody">');

							canvasIdStr = 'cvsTitleBonusPrizes';
							elementStr  = 'eleTitleBonusPrizes';
							cellStr     = getTranslationByName("titleBonusPrizes", translations);

							r.push('<td>');

							showSymb(canvasIdStr, elementStr, cellBonusHeight, colourBlack, cellStr, doRotate, doTitle);

							r.push('</td>');

							for (var turnIndex = 0; turnIndex < bonusTurnsQty; turnIndex++)
							{
								canvasIdStr = 'cvsGridBonus' + turnIndex.toString();
								elementStr  = 'eleGridBonus' + turnIndex.toString();

								r.push('<td>');

								showBonusPrizes(canvasIdStr, elementStr, scenarioBonusGame[turnIndex].split(':'));

								r.push('</td>');
							}

							r.push('</tr>');
							r.push('</table>');

							/////////////////////
							// Bonus Game Wins //
							/////////////////////

							var bonusTurnData  = [];
							var bonusPrizeData = '';
							var bonusMultiQty  = 1;
							var bonusPrizes    = [];

							for (var turnIndex = 0; turnIndex < bonusTurnsQty; turnIndex++)
							{
								bonusTurnData = scenarioBonusGame[turnIndex].split(':');

								for (var prizeIndex = 0; prizeIndex < bonusTurnData.length; prizeIndex++)
								{
									bonusPrizeData = bonusTurnData[prizeIndex];

									if (bonusPrizeData[0] == 'm')
									{
										bonusMultiQty += parseInt(bonusPrizeData[1]);
									}
									else if (bonusPrizeData[0] == 'b')
									{
										bonusPrizes.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, bonusPrizeData.toUpperCase())]);
									}
								}
							}

							showBonusTotal(bonusPrizes, bonusMultiQty);
						}

						r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					function getScenario(jsonContext)
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getPrizesData(scenario)
					{
						return scenario.split("|")[0];
					}

					function getMainGameData(scenario)
					{
						return scenario.split("|").slice(1,9);
					}

					function getBonusGameData(scenario)
					{
						return scenario.split("|")[9].split(",");
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
