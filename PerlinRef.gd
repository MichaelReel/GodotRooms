# Lifted from: http://mrl.nyu.edu/~perlin/noise/

var p
var min_hash
var max_hash
var dx
var dy
var dz

func _init(width = 1, height = 1, depth = 1, zoom = 1, init_seed = 0):
	self.p = []
	self.min_hash = 0.0
	self.max_hash = 0.0
	self.dx = float(zoom) / width
	self.dy = float(zoom) / height
	self.dz = float(zoom) / depth
	var permutation = self.getPermutation(init_seed)
	for i in range(512):
	    self.p.append(permutation[i % permutation.size()])

func getPermutation(init_seed):
	var map = []
	var perm = []
	for i in range(256):
		map.append(i)
		perm.append(0)
	
	for src in range(255, -1, -1):
		init_seed = int(init_seed * 6364136223846793005 + 1442695040888963407)
		var dst = (init_seed % (src+1))
		perm[src] = map[dst];
		map[dst] = map[src];

	return perm

func getFloatHash(x, y, z = 0):
	var X = int(floor(x)) & 255             # FIND UNIT CUBE THAT
	var Y = int(floor(y)) & 255             # CONTAINS POINT.
	var Z = int(floor(z)) & 255
	x -= floor(x)                           # FIND RELATIVE X,Y,Z
	y -= floor(y)                           # OF POINT IN CUBE.
	z -= floor(z)
	var u = fade(x)                         # COMPUTE FADE CURVES
	var v = fade(y)                         # FOR EACH OF X,Y,Z.
	var w = fade(z) 
	var A  = self.p[X]+Y                    # HASH COORDINATES OF
	var AA = self.p[A]+Z                    # THE 8 CUBE CORNERS,
	var AB = self.p[A+1]+Z
	var B  = self.p[X+1]+Y
	var BA = self.p[B]+Z
	var BB = self.p[B+1]+Z

	return lerp(lerp(lerp(grad(self.p[AA  ], x  , y  , z   ),         # AND ADD
						  grad(self.p[BA  ], x-1, y  , z   ), u),     # BLENDED
					 lerp(grad(self.p[AB  ], x  , y-1, z   ),         # RESULTS
						  grad(self.p[BB  ], x-1, y-1, z   ), u), v), # FROM  8
				lerp(lerp(grad(self.p[AA+1], x  , y  , z-1 ),         # CORNERS
						  grad(self.p[BA+1], x-1, y  , z-1 ), u),     # OF CUBE
					 lerp(grad(self.p[AB+1], x  , y-1, z-1 ),
						  grad(self.p[BB+1], x-1, y-1, z-1 ), u), v), w);

func getHash(x, y, z = 0):
	return float(self.getFloatHash(x * self.dx, y * self.dy, z * self.dz))
	
func fractal2d(octaves, persistence, x, y, z = 0, accel_freq = 2):
	"""
	Generate 2D Fractal noise 
	"""
	var total = 0
	var frequency = 1
	var amplitude = 1
	var maxValue = 0
	for i in range(octaves, 0, -1):
		total += getHash(x / frequency, y / frequency, z / frequency) * amplitude
		
		maxValue += amplitude
		
		amplitude *= persistence
		frequency *= accel_freq
	
	return total / maxValue

func fade(t):
	return t * t * t * (t * (t * 6 - 15) + 10)

func grad(hsh, x, y, z):
	var h = hsh & 15;                      # CONVERT LO 4 BITS OF HASH CODE
	var u = x if h<8 else y                # INTO 12 GRADIENT DIRECTIONS.
	var v = y if h<4 else x if h==12 or h==14 else z
	return (u if (h&1) == 0 else -u) + (v if (h&2) == 0 else -v)