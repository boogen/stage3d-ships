package
{
    [SWF(width="1600", height="1200", backgroundColor="#FFFFFF")]

    import com.adobe.utils.*;
    import flash.system.ApplicationDomain;
    import flash.display.*;
    import flash.display3D.*;
    import flash.display3D.textures.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.utils.*;
    import flash.text.*;

    public class shiprenderer extends Sprite
    {
	private const SHIPS_COUNT:int = 100;
	private const ARENA_SIZE:int = 40;
	private const FPS:int = 60;

	private var context3D:Context3D;

	//fps counter
	private var fpsLast:uint = getTimer();
	private var fpsTicks:uint = 0;
	private var fpsTf:TextField;
	private var scoreTf:TextField;
	
	//constants
	private const swfWidth:int = 1200;
	private const swfHeight:int = 1024;
	private const textureSize:int = 128;
	private const flagTextureSize:int = 32;
	
	[Embed(source = "assets/s1a.jpg")]
	private var hullTextureBitmap1:Class;
	private var hullTextureData1:Bitmap = new hullTextureBitmap1();
	[Embed(source = "assets/ss1a.jpg")]
	private var sailTextureBitmap1:Class;
	private var sailTextureData1:Bitmap = new sailTextureBitmap1();
	[Embed(source = "assets/red.jpg")]
	private var flagTextureBitmap1:Class;
	private var flagTextureData1:Bitmap = new flagTextureBitmap1();

	[Embed(source = "assets/s2a.jpg")]
	private var hullTextureBitmap2:Class;
	private var hullTextureData2:Bitmap = new hullTextureBitmap2();
	[Embed(source = "assets/ss0a.jpg")]
	private var sailTextureBitmap2:Class;
	private var sailTextureData2:Bitmap = new sailTextureBitmap2();
	[Embed(source = "assets/txt_flag_sm_blue.gif")]
	private var flagTextureBitmap2:Class;
	private var flagTextureData2:Bitmap = new flagTextureBitmap2();


	[Embed(source = "assets/s11b.jpg")]
	private var hullTextureBitmap3:Class;
	private var hullTextureData3:Bitmap = new hullTextureBitmap3();
	[Embed(source = "assets/ss_ManOWar.jpg")]
	private var sailTextureBitmap3:Class;
	private var sailTextureData3:Bitmap = new sailTextureBitmap3();
	[Embed(source = "assets/txt_flag_sm_pink.gif")]
	private var flagTextureBitmap3:Class;
	private var flagTextureData3:Bitmap = new flagTextureBitmap3();


	[Embed(source = "assets/water.jpg")]
	private var waterTextureBitmap:Class;
	private var waterTextureData:Bitmap = new waterTextureBitmap();

	
	private var waterTexture:Texture;

	private var hullTextures:Vector.<Texture>;
	private var sailTextures:Vector.<Texture>;
	private var flagTextures:Vector.<Texture>;

	private var hullMeshes:Vector.<Stage3dObjParser>;
	private var sailMeshes:Vector.<Stage3dObjParser>;
	private var flagMeshes:Vector.<Stage3dObjParser>;

	[Embed (source = "assets/sh1_hull.obj", mimeType="application/octet-stream")]
	private var hullObjData1:Class;
	
	[Embed (source = "assets/sh1_sails.obj", mimeType="application/octet-stream")]
	private var sailObjData1:Class;

	[Embed(source = "assets/sh1_flag.obj", mimeType="application/octet-stream")]
	private var flagObjData1:Class;

	[Embed (source = "assets/sh2_hull.obj", mimeType="application/octet-stream")]
	private var hullObjData2:Class;
	
	[Embed (source = "assets/sh2_sails.obj", mimeType="application/octet-stream")]
	private var sailObjData2:Class;

	[Embed(source = "assets/sh2_flag.obj", mimeType="application/octet-stream")]
	private var flagObjData2:Class;

	[Embed (source = "assets/sh11_hull.obj", mimeType="application/octet-stream")]
	private var hullObjData3:Class;
	
	[Embed (source = "assets/sh11_sails.obj", mimeType="application/octet-stream")]
	private var sailObjData3:Class;

	[Embed(source = "assets/sh11_flag.obj", mimeType="application/octet-stream")]
	private var flagObjData3:Class;


	private var shaderProgram:Program3D;
	private var shaderProgramWater:Program3D;

//	private var projectionmatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
        private var projectionmatrix:Matrix3D = new Matrix3D();
	private var viewmatrix:Matrix3D = new Matrix3D();
	private var modelmatrix:Matrix3D = new Matrix3D();
	private var modelViewProjection:Matrix3D = new Matrix3D();

	private var t:Number = 0.0;

	private var currentPosition:Vector.<Point>;
	private var nextPosition:Vector.<Point>;

	private var lastDegrees:Vector.<Number>;
	private var shipModel:Vector.<uint>;
	private var shipSpeed:Vector.<Number>;

	private var waterIndexBuffer:IndexBuffer3D;
	private var waterVertexBuffer:VertexBuffer3D;


	private var shipMap:Dictionary = new Dictionary();

	private var lastTick:Number;

	public function shiprenderer():void
	{
	    if (stage != null)
	    {
		init();
	    }
	    else
	    {
		addEventListener(Event.ADDED_TO_STAGE, init);
	    }
	}

	private function init(e:Event = null):void
	{	    
	    if (hasEventListener(Event.ADDED_TO_STAGE))
	    {
		removeEventListener(Event.ADDED_TO_STAGE, init);
	    }

	    stage.frameRate = FPS;

	    stage.scaleMode = StageScaleMode.NO_SCALE;
	    stage.align = StageAlign.TOP_LEFT;

	    currentPosition = new Vector.<Point>(SHIPS_COUNT, true);
	    nextPosition = new Vector.<Point>(SHIPS_COUNT, true);
	    lastDegrees = new Vector.<Number>(SHIPS_COUNT, true);
	    shipModel = new Vector.<uint>(SHIPS_COUNT, true);
	    shipSpeed = new Vector.<Number>();
	    shipSpeed.push(8);
	    shipSpeed.push(10);
	    shipSpeed.push(12);
	    
	    for (var i:uint = 0; i < SHIPS_COUNT; ++i)
	    {
		currentPosition[i] = getRandomPosition();
		nextPosition[i] = new Point(0, 0);
		getNextPosition(nextPosition[i]);
		lastDegrees[i] = 0;
		shipModel[i] =  Math.floor(Math.random() * 3);
		
	    }

	    lastTick = getTimer();

	    initGUI();

	    var stage3DAvailable:Boolean = ApplicationDomain.currentDomain.hasDefinition("flash.display.Stage3D");
	    if (stage3DAvailable)
	    {
		stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
		stage.stage3Ds[0].addEventListener(ErrorEvent.ERROR, onStage3DError);
		stage.stage3Ds[0].requestContext3D();
	    }
	    else
	    {
		fpsTf.text = "stage 3d is not available";
		trace("stage 3d is not available");
	    }
	}

	private function initGUI():void
	{
	    var myFormat:TextFormat = new TextFormat();
	    myFormat.color = 0x000000;
	    myFormat.size = 13;

	    fpsTf = new TextField();
	    fpsTf.x = 0;
	    fpsTf.y = 0;
	    fpsTf.selectable = false;
	    fpsTf.autoSize = TextFieldAutoSize.LEFT;
	    fpsTf.defaultTextFormat = myFormat;
	    fpsTf.text = "Initializing Stage3d...";
	    addChild(fpsTf);
	}

	private function onContext3DCreated(e:Event):void
	{

	    if (hasEventListener(Event.ENTER_FRAME))
	    {
		removeEventListener(Event.ENTER_FRAME, enterFrame);
	    }
	    var t:Stage3D = e.target as Stage3D;
	    context3D = t.context3D;

	    if (context3D == null)
	    {
		fpsTf.text = "context 3D is null";
		return;
	    }

	    context3D.enableErrorChecking = false;
	    
	    initData();
	    context3D.configureBackBuffer(swfWidth, swfHeight, 2, true);

	    initShaders();
	    
	    waterTexture = context3D.createTexture(waterTextureData.bitmapData.width, waterTextureData.bitmapData.height, Context3DTextureFormat.BGRA, false);
	    waterTexture.uploadFromBitmapData(waterTextureData.bitmapData);
	    
	    hullTextures = new Vector.<Texture>();
	    sailTextures = new Vector.<Texture>();
	    flagTextures = new Vector.<Texture>();
	    
	    var hullTexture:Texture;
	    var sailTexture:Texture;
	    var flagTexture:Texture;


	    var ht:Array = [hullTextureData1, hullTextureData2, hullTextureData3];
	    var st:Array = [sailTextureData1, sailTextureData2, sailTextureData3];
	    var ft:Array = [flagTextureData1, flagTextureData2, flagTextureData3];

	    for (var i:uint = 0; i < ht.length; ++i)
	    {

		hullTexture = context3D.createTexture(textureSize, textureSize, Context3DTextureFormat.BGRA, false);
		uploadTextureWithMipmaps(hullTexture, ht[i].bitmapData);
		hullTextures.push(hullTexture);

		sailTexture = context3D.createTexture(textureSize, textureSize, Context3DTextureFormat.BGRA, false);
		uploadTextureWithMipmaps(sailTexture, st[i].bitmapData);
		sailTextures.push(sailTexture);

		flagTexture = context3D.createTexture(flagTextureSize, flagTextureSize, Context3DTextureFormat.BGRA, false);
		uploadTextureWithMipmaps(flagTexture, ft[i].bitmapData);
		flagTextures.push(flagTexture);
	    }



//	    projectionmatrix.identity();
//	    projectionmatrix.perspectiveFieldOfViewRH(45.0, swfWidth / swfHeight, 0.01, 5000.0);
            projectionmatrix = createOrthographicProjectionMatrix(100, 100, 0.01, 50.0);

	    viewmatrix.identity();
	    viewmatrix.appendTranslation(0, 0, 10);

	    addEventListener(Event.ENTER_FRAME, enterFrame);
	    
	}

	private function createOrthographicProjectionMatrix(viewWidth:Number, viewHeight:Number, near:Number, far:Number):Matrix3D
	{
	    // this is a projection matrix that gives us an orthographic view of the world (meaning there's no perspective effect)
	    // the view is defined with (0,0) being in the middle,
	    //	(-viewWidth / 2, -viewHeight / 2) at the top left,
	    // 	(viewWidth / 2, viewHeight / 2) at the bottom right,
	    //	and 'near' and 'far' giving limits to the range of z values for objects to appear.
	    return new Matrix3D(Vector.<Number>
		([
			2/viewWidth, 0, 0, 0,
			0, 2/viewHeight, 0, 0,
			0, 0, 1/(far-near), -near/(far-near),
			0, 0, 0, 1
		    ]));
	}
	
	private function initData():void
	{
	    hullMeshes = new Vector.<Stage3dObjParser>();
	    sailMeshes = new Vector.<Stage3dObjParser>();
	    flagMeshes = new Vector.<Stage3dObjParser>();
	    
	    hullMeshes.push(new Stage3dObjParser(hullObjData1, context3D, 1, true, true));
	    sailMeshes.push(new Stage3dObjParser(sailObjData1, context3D, 1, true, true));
	    flagMeshes.push(new Stage3dObjParser(flagObjData1, context3D, 1, true, true));

	    hullMeshes.push(new Stage3dObjParser(hullObjData2, context3D, 1, true, true));
	    sailMeshes.push(new Stage3dObjParser(sailObjData2, context3D, 1, true, true));
	    flagMeshes.push(new Stage3dObjParser(flagObjData2, context3D, 1, true, true));

	    hullMeshes.push(new Stage3dObjParser(hullObjData3, context3D, 1, true, true));
	    sailMeshes.push(new Stage3dObjParser(sailObjData3, context3D, 1, true, true));
	    flagMeshes.push(new Stage3dObjParser(flagObjData3, context3D, 1, true, true));


	    var waterIndexData:Vector.<uint> = Vector.<uint>([0, 1, 2, 0, 2, 3]);
	    var waterVertexData:Vector.<Number> = Vector.<Number>
	    ([
		    //X, Y, Z,  U, V,
		    -1, -1, 1,  0, 0,
		    1,  -1, 1,  1, 0,
		    1,   1, 1,  1, 1,
		    -1,  1, 1,  0, 1
	    ]);
	    
	    waterIndexBuffer = context3D.createIndexBuffer(waterIndexData.length);
	    waterIndexBuffer.uploadFromVector(waterIndexData, 0, waterIndexData.length);

	    waterVertexBuffer = context3D.createVertexBuffer(waterVertexData.length/5, 5);
	    waterVertexBuffer.uploadFromVector(waterVertexData, 0, waterVertexData.length/5);
	    
	}

	private function getRandomPosition():Point
	{
	    var MAX:int = ARENA_SIZE;
	    return new Point(Math.floor(Math.random() * 2 * MAX) - MAX, Math.floor(Math.random() * 2 * MAX) - MAX);
	}

	private function getNextPosition(pos:Point):void
	{
	    var MAX:int = ARENA_SIZE;

	    var r:int = Math.floor(Math.random() * 2 * MAX) - MAX;
	    var sign:int = Math.floor(Math.random() * 2) * 2 - 1;
	    if (pos.x == -MAX)
	    {
		pos.y = sign * MAX;
		pos.x = r; 
	    }
	    else if (pos.y == -MAX)
	    {
		pos.x = sign * MAX;
		pos.y = r; 
	    }
	    else if (pos.x == MAX)
	    {
		pos.y = sign * MAX;
		pos.x = r;
	    }
	    else 
	    {
		pos.x = sign * MAX;
		pos.y = r;
	    }
	}

	private function getDegrees(degrees:int, lastDegrees:int):int
	{
		var d:Number = degrees - lastDegrees;
		while (d < -180)
		{
		    d += 360;
		}
		while (d > 180)
		{
		    d -= 360;
		}

		if (Math.abs(d) > 10)
		{
		    d = d / Math.abs(d) * 10;
		}

		return lastDegrees + d;
	    
	}


	private function enterFrame(e:Event):void
	{	    
	    if (context3D.driverInfo == "Disposed")
	    {
		removeEventListener(Event.ENTER_FRAME, enterFrame);
		return;
	    }

	    var tick:Number = getTimer();
	    var dt:Number = tick - lastTick;
	    lastTick = tick;
	    var percent:Number = dt / 1000;

	    context3D.clear(1, 1, 1);

    	    context3D.setProgram(shaderProgramWater);

	    modelmatrix.identity();
	    modelmatrix.appendScale(ARENA_SIZE, ARENA_SIZE, 1);
	  //  modelmatrix.appendTranslation(0, 0, 45 );
	    context3D.setTextureAt(0, waterTexture);
	
	    modelViewProjection.identity();
	    modelViewProjection.append(modelmatrix);
	    modelViewProjection.append(viewmatrix);
	    modelViewProjection.append(projectionmatrix);

	    context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelViewProjection, true);
	    context3D.setVertexBufferAt(0, waterVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
	    context3D.setVertexBufferAt(1, waterVertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
	    context3D.drawTriangles(waterIndexBuffer, 0, 2);
	    

	    t += 2.0;
  	    context3D.setProgram(shaderProgram);

	    
	    for (var i:uint = 0; i < SHIPS_COUNT; ++i)
	    {

		if (currentPosition[i].subtract(nextPosition[i]).length < 1)
		{
		    getNextPosition(nextPosition[i]);
		}
		
		var diff:Point = nextPosition[i].subtract(currentPosition[i]);
		var radians:Number = Math.atan2(diff.y, diff.x);
		var degrees:Number = (radians / Math.PI) * 180;

		lastDegrees[i] = getDegrees(degrees, lastDegrees[i]);
	   
		
		diff.normalize(percent * shipSpeed[shipModel[i]]);
		currentPosition[i] = currentPosition[i].add(diff);



		modelmatrix.identity();
		modelmatrix.appendRotation(90, Vector3D.Z_AXIS);
		modelmatrix.appendRotation(-lastDegrees[i] + 180, Vector3D.Y_AXIS);
		modelmatrix.appendRotation(-45, Vector3D.X_AXIS);
		modelmatrix.appendTranslation(currentPosition[i].x, currentPosition[i].y, 0);
	    
		modelViewProjection.identity();
		modelViewProjection.append(modelmatrix);
		modelViewProjection.append(viewmatrix);
		modelViewProjection.append(projectionmatrix);
		context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelViewProjection, true);

		for (var j:uint = 0; j < 3; ++j)
		{

		    switch (j)
		    {
			case 0:
			context3D.setTextureAt(0, hullTextures[shipModel[i]]);
			break;
			case 1:
       	    		context3D.setTextureAt(0, sailTextures[shipModel[i]]);
			break;
			case 2:
			context3D.setTextureAt(0, flagTextures[shipModel[i]]);
			break;
		    }



		    
		    var mesh:Stage3dObjParser;
		    switch (j)
		    {
			case 0:
		        mesh = hullMeshes[shipModel[i]];
			break;
			case 1:
		        mesh = sailMeshes[shipModel[i]];
			break;
			case 2:
		        mesh = flagMeshes[shipModel[i]];
			break
	            }
		         
 		    context3D.setVertexBufferAt(0, mesh.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		    context3D.setVertexBufferAt(1, mesh.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		    context3D.drawTriangles(mesh.indexBuffer, 0, mesh.indexBufferCount);

		}
	    }

	    context3D.present();

	    fpsTicks++;
	    var now:uint = getTimer();
	    var delta:uint = now - fpsLast;
	    if (delta >= 1000)
	    {
		var fps:Number = fpsTicks / delta * 1000;
		fpsTf.text = fps.toFixed(1) + " fps";
		fpsTicks = 0;
		fpsLast = now;
	    }
	}

	private function initShaders():void
	{
	    var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();

	    vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, 
		"m44 op, va0, vc0\n" +
		"mov v0, va1"
		);

		

	    var fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
	    
	    fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, 
		"tex ft0, v0, fs0 <2d, repeat, miplinear>;\n" +
		"mov oc, ft0"
		);


	    var fragmentShaderWaterAssembler:AGALMiniAssembler = new AGALMiniAssembler();
	    
	    fragmentShaderWaterAssembler.assemble(Context3DProgramType.FRAGMENT, 
		"tex ft0, v0, fs0 <2d, repeat, nomip>;\n" +
		"mov oc, ft0"
		);
		

	    shaderProgram = context3D.createProgram();
	    shaderProgram.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);

	    shaderProgramWater = context3D.createProgram();
	    shaderProgramWater.upload(vertexShaderAssembler.agalcode, fragmentShaderWaterAssembler.agalcode);
	}

	private function onStage3DError(e:Event):void
	{

	}

	public function uploadTextureWithMipmaps(dest:Texture, src:BitmapData):void
	{
	    var ws:int = src.width;
	    var hs:int = src.height;
	    var level:int = 0;
	    var tmp:BitmapData;
	    var transform:Matrix = new Matrix();
	    var tmp2:BitmapData;

	    tmp = new BitmapData(src.width, src.height, true, 0x00000000);

	    while (ws >= 1 && hs >= 1)
	    {
		tmp.draw(src, transform, null, null, null, true);
		dest.uploadFromBitmapData(tmp, level);
		transform.scale(0.5, 0.5);
		level++;
		ws >>= 1;
		hs >>= 1;
		if (hs && ws)
		{
		    tmp.dispose();
		    tmp = new BitmapData(ws, hs, true, 0x00000000);
		}
	    }
	    tmp.dispose();
	}
    }
}