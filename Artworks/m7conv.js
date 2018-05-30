(function() {
	'use strict';

	var gCanvas = null;
	var gG = null;
	var gSrcImage = null;
	var gPalette = null;

	var gMapG = null;

	var PAL_Y = 97;
	var AnimatePalette = 40;

	var gTileBytes = [];
	var gMapBytes = [];

	var gTileMap = {};
	var kINTV = 32;

	window.onload = function() {
		gSrcImage = new Image();
		gSrcImage.onload = afterLoad;

		gCanvas = document.getElementById('cv1');
		gG = gCanvas.getContext('2d');

		var cv_m = document.getElementById('map-cv');
		gMapG = cv_m.getContext('2d');


		gSrcImage.src = kImageData;
	};

	function afterLoad() {
		gG.drawImage(gSrcImage, 0, 0);
		gPalette = pickPalette();

		for (var y = 0;y < 12;++y) {
			for (var x = 0;x < 16;++x) {
				processTile(gTileBytes, x*8, y*8);
			}
		}

		generateMap();
		mapToBytes(gMapBytes);
		renderMapAll();

		var byteArray = generateBinImage(gMapBytes, gTileBytes);

		var blob = new Blob([byteArray] , { "type" : "application/octet-stream" });
		var a = document.createElement('a');
		a.href = window.URL.createObjectURL(blob);
		a.download = 'm7map.bin';
		a.innerHTML = 'Save...';

		document.body.appendChild(a);
		emitPalette();
		emitPaletteAnimation( AnimatePalette );
	}

	function emitPalette() {
		var items = [];

		var n = gPalette.length;
		for (var i = 0;i < n;++i) {
			var c = gPalette[i];
			var w = ((c.B >> 3) << 10) | ((c.G >> 3) << 5) | (c.R >> 3);
			var hx = color_to_hex(c.R , c.G , c.B);

			var ret = (i%16) === 15 ? '\n' : '';
			items.push('$'+hx + ret);
		}

		console.log(  items.join(', ')  );
	}

	function color_to_hex(r, g, b) {
		var w = ((b >> 3) << 10) | ((g >> 3) << 5) | (r >> 3);
		var hx = w.toString(16);
		if (hx.length < 4) { hx = '0' + hx; }
		if (hx.length < 4) { hx = '0' + hx; }
		if (hx.length < 4) { hx = '0' + hx; }
		return hx;
	}

	function emitPaletteAnimation(index) {
		var parts = [];
		for (var i = 0;i < 16;++i) {
			var ent = gPalette[index];
			var add_r = (15-i) * 15;
			var add_g = (15-i) *  8;
			var add_b = (15-i) *  4;

			var r = Math.min(255, ent.R + add_r);
			var g = Math.min(255, ent.G + add_g);
			var b = Math.min(255, ent.B + add_b);

			var hx = color_to_hex(r , g , b);
			parts.push( '$' + hx );
		}

		console.log("AnimColorTable:\n.word " + parts.join(', '));
	}

	function generateBinImage(a1, a2) {
		var b = new Uint8Array(128*256);

		var rpos = 0;
		for (var y = 0;y < 128;++y) {
			for (var x = 0;x < 128;++x) {
				var m = a1[rpos];
				b[rpos*2] = m;
				++rpos;
			}
		}

		var len = a2.length;
		for (var i = 0;i < len;++i) {
			b[i*2 +1] = a2[i];
		}

		return b;
	}

	function mapToBytes(outArr) {
		for (var y = 0;y < 128;++y) {
			for (var x = 0;x < 128;++x) {
				var t = gTileMap[  XYtoKey(x, y)  ];
				outArr.push(t);
			}
		}
	}

	function generateMap() {
		var x,y;
		for (y = 0;y < 32;++y) {
			for (x = 0;x < 32;++x) {
				genPipe(x*4, y*4, (x+y)%2);
			}
		}

		for (x = 0;x < 6;++x) {
			genShadowsV(x*kINTV-1);
			genShadowsV(x*kINTV+2);
			genShadowsV(x*kINTV+5);
			genShadowsV(x*kINTV+8);
		}

		for (y = 0;y < 6;++y) {
			genShadowsH(y*kINTV-1);
			genShadowsH(y*kINTV+2);
			genToraH(y*kINTV);
//			genPanelsH(y*kINTV+2);
			genToraH(y*kINTV+6);
			genShadowsH(y*kINTV+5);
			genShadowsH(y*kINTV+8);
		}

		for (x = 0;x < 6;++x) {
			genToraV(x*kINTV);
//			genPanelsV(x*kINTV+2);
			genToraV(x*kINTV+6);
		}

		for (y = 0;y < 6;++y) {
			for (x = 0;x < 6;++x) {
				putSmallPanel(x*kINTV  , y*kINTV  );
				putSmallPanel(x*kINTV+6, y*kINTV  );
				putSmallPanel(x*kINTV  , y*kINTV+6);
				putSmallPanel(x*kINTV+6, y*kINTV+6);
				putAPanel(x*kINTV +2, y*kINTV +2);

				if ( (x === 0) || (y === 0)) {
					putChainPanelsArray(x*kINTV+8, y*kINTV+8, 3, 6);
				}

				if (x === 0) {
					putVPanels(8, y*kINTV+2, 24);
					putVPanels(8, y*kINTV+3, 24);
					putVPanels(8, y*kINTV+4, 24);
					putVPanels(8, y*kINTV+5, 24);
				}

				if (y === 0) {
					putHPanels(x*kINTV+2, 8, 24);
					putHPanels(x*kINTV+3, 8, 24);
					putHPanels(x*kINTV+4, 8, 24);
					putHPanels(x*kINTV+5, 8, 24);
				}
			}
		}

	}

	function pickPalette() {
		var g = gG;
		var ls = [];

//		var flag_imagedata = gG.getImageData(0, PAL_Y+5, 64, 1);
//		var fp = flag_imagedata.data;

		var imagedata = gG.getImageData(0, PAL_Y, 64, 1);
		var p = imagedata.data;
		for (var i = 0;i < 64;++i) {

			ls.push({
				R : p[i*4   ],
				G : p[i*4 +1],
				B : p[i*4 +2]
			});
		}

		return ls;
	}

	function processTile(outArr, ox, oy) {
		var imagedata = gG.getImageData(ox, oy, 8, 8);
		var p = imagedata.data;

		var pos = 0;
		for (var y = 0;y < 8;++y) {
			for (var x = 0;x < 8;++x) {
				var cR = p[pos++];
				var cG = p[pos++];
				var cB = p[pos++];
				pos++;

				var ci = pickColorIndex(cR, cG, cB);
				if (ci < 0) { throw "Bad color at " + (ox+x) +','+ (oy+y);}

				outArr.push(ci);
			}
		}
		
	}

	function pickColorIndex(cR, cG, cB) {
		var n = gPalette.length;
		for (var i = 0;i < n;++i) {
			var c = gPalette[i];
			if (c.R === cR && c.G === cG && c.B === cB) {
				return i;
			}
		}

		return -1;
	}

	// MAP

	function XYtoKey(x, y) {
		return x + '_' + y;
	}

	function renderMapAll() {

		for (var y = 0;y < 128;++y) {
			for (var x = 0;x < 128;++x) {
				var t = gTileMap[ XYtoKey(x, y) ] || 0;

				putTile(x, y, t);
			}
		}

	}

	function genPipe(x, y, type) {
		var b = type*4;

		for (var i = 0;i < 4;++i) {
			gTileMap[  XYtoKey(x  , y)  ] = b;
			gTileMap[  XYtoKey(x+1, y)  ] = b+1;
			gTileMap[  XYtoKey(x+2, y)  ] = b+2;
			gTileMap[  XYtoKey(x+3, y)  ] = b+3;

			++y;
			b += 16;
		}
	}

	function genToraH(y) {
		for (var i = 0;i < 128;++i) {
			gTileMap[  XYtoKey(i , y)  ] = 72;
			gTileMap[  XYtoKey(i , y+1)] = 73;
		}
	}

	function genToraV(x) {
		for (var i = 0;i < 128;++i) {
			gTileMap[  XYtoKey(x   , i) ] = 74;
			gTileMap[  XYtoKey(x+1 , i) ] = 75;
		}
	}

	function randomStain() {
		return (Math.random() < 0.9) ? 0 : 4;
	}

	function putAPanel(x, y) {
		var ti = 64;
		for (var j = 0;j < 4;++j) {
			gTileMap[  XYtoKey(x  , y)] = randomStain() + ti;
			gTileMap[  XYtoKey(x+1, y)] = randomStain() + ti+1;
			gTileMap[  XYtoKey(x+2, y)] = randomStain() + ti+2;
			gTileMap[  XYtoKey(x+3, y)] = randomStain() + ti+3;
			++y;
			ti += 16;
		}
	}

	function putChainPanelsArray(x, y, w, h) {
		for (var j = 0;j < h;++j) {
			for (var i = 0;i < w;++i) {
				putAChainPanel(x + i*8   , y + j*4, 0);
				putAChainPanel(x + i*8 +4, y + j*4, 1);
			}
		}
	}

	function putAChainPanel(x, y, type) {
		var ti = 128 + type*4;
		for (var j = 0;j < 4;++j) {
			gTileMap[  XYtoKey(x  , y)] = ti;
			gTileMap[  XYtoKey(x+1, y)] = ti+1;
			gTileMap[  XYtoKey(x+2, y)] = ti+2;
			gTileMap[  XYtoKey(x+3, y)] = ti+3;
			++y;
			ti += 16;
		}
	}

	function putSmallPanel(x, y) {
		var ti = 88;
		gTileMap[  XYtoKey(x  , y  )] = ti;
		gTileMap[  XYtoKey(x+1, y  )] = ti+1;
		gTileMap[  XYtoKey(x  , y+1)] = ti+2;
		gTileMap[  XYtoKey(x+1, y+1)] = ti+3;
	}

	function putVPanels(x, y, cols) {
		var ti = 92;
		for (var i = 0;i < cols;++i) {
			gTileMap[  XYtoKey(x+i, y)] = ti;
		}
	}

	function putHPanels(x, y, rows) {
		var ti = 93;
		for (var i = 0;i < rows;++i) {
			gTileMap[  XYtoKey(x, y+i)] = ti;
		}
	}

	function shouldSkipPanel(a) {
		return ( (a % kINTV) === 0 || (a % kINTV) === 6 ) ? 2 : 0;
	}

	function genPanelsH(y) {
		var x = -2;
		for (var i = 0;i < 29;++i) {
			x += shouldSkipPanel(x);
			putAPanel(x, y);
			x += 4;
		}
	}

	function genShadowsH(y) {
		for (var i = 0;i < 128;++i) {
			var old = gTileMap[  XYtoKey(i, y)  ];
			if ((old % 16) < 8) {
				gTileMap[  XYtoKey(i, y)  ] += 8;
			}
		}
	}

	function genShadowsV(x) {
		for (var i = 0;i < 128;++i) {
			var old = gTileMap[  XYtoKey(x, i)  ];
			if ((old % 16) < 8) {
				gTileMap[  XYtoKey(x, i)  ] += 8;
			}
		}
	}

	function genPanelsV(x) {
		var y = -4;
		for (var i = 0;i < 29;++i) {
			y += shouldSkipPanel(y);
			putAPanel(x, y);
			y += 4;
		}
	}


	// TILE
	function putTile(cx, cy, tileIndex) {
		var x = cx * 8;
		var y = cy * 8;

		var tX = 8 * (tileIndex % 16);
		var tY = 8 * Math.floor(tileIndex / 16);

		gMapG.drawImage( gCanvas, tX, tY, 8, 8, x, y, 8, 8 );
	}


})();