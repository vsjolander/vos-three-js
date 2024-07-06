import * as THREE from 'three'
import Scene from "./scene";
import Camera from "./camera";
import Renderer from "./renderer";
import Controls from "./controls";
import fragmentShader from '../assets/glsl/fragment.glsl';
import iridescentFragmentShader from '../assets/glsl/iridescent-fragment.glsl';
import vertexShader from '../assets/glsl/vertex.glsl';

//Converting colors to proper format
function normalizeColor(hexCode: string) {
  return [(hexCode >> 16 & 255) / 255, (hexCode >> 8 & 255) / 255, (255 & hexCode) / 255]
}


export default class App {
  canvas = document.getElementById('vos-canvas') as HTMLCanvasElement
  computedCanvasStyle = getComputedStyle(this.canvas)
  scene;
  camera;
  renderer;
  controls;
  conf = {
    presetName: "",
    wireframe: false,
    density: [.06, .16],
    zoom: 1,
    rotation: 0,
    playing: true
  }
  seed = 5;
  time = 0;
  last: number = 0;
  width = window.innerWidth
  height = window.innerHeight
  sectionColors: number[][] = [];
  material: THREE.ShaderMaterial | undefined;
  iridescentMaterial: THREE.MeshPhysicalMaterial | undefined;
  xSegments = Math.ceil(this.width * this.conf.density[0])
  ySegments = Math.ceil(this.height * this.conf.density[0])
  geometry = new THREE.PlaneGeometry(this.width / 2, this.height / 2, this.xSegments, this.ySegments)
  plane : THREE.Mesh<THREE.PlaneGeometry> | undefined
  pointLight = new THREE.PointLight(0xffffff, 2)
  constructor() {
    this.scene = new Scene()
    this.camera = new Camera()
    this.renderer = new Renderer(this.canvas, this.width, this.height)
    //this.controls = new Controls(this.camera.orthographicCamera, this.canvas)

    this.camera.orthographicCamera.position.set(-1,-1,-1)
    this.pointLight.position.set(10,10,10)

    this.camera.orthographicCamera.updateProjectionMatrix()

    this.render.bind(this)

    this.init()

    requestAnimationFrame((e) => this.render(e))
  }



  createUvNormAttribute() {
    const uvNorm = new Float32Array(this.geometry.attributes.uv.count * 2)

    this.geometry.attributes.uv.array.map((item: number, index) => {
      uvNorm[index] = 2 * item - 1
    })

    this.geometry.setAttribute('uvNorm', new THREE.Float32BufferAttribute(uvNorm, 2))
  }

  initGradientColors() {
    this.sectionColors = ["--gradientColorZero", "--gradientColorOne", "--gradientColorTwo", "--gradientColorThree"].map(cssPropertyName=>{
        let hex = this.computedCanvasStyle.getPropertyValue(cssPropertyName).trim();
        if (4 === hex.length) {
          const hexTemp = hex.substr(1).split("").map(hexTemp=>hexTemp + hexTemp).join("");
          hex = `#${hexTemp}`
        }
        return hex && `0x${hex.substr(1)}`
      }
    ).filter(Boolean).map(normalizeColor)
  }

  initMaterial() {
    const uniforms = {
      u_time: {value: 0},
      u_resolution: {value: new THREE.Vector2(this.width, this.height)},
      u_shadow_power: {
        value: 5
      },
      u_darken_top: {
        value: 1
      },
      u_active_colors: {
        value: new THREE.Vector4(1, 1, 1, 1),
      },
      u_global: {
        value: {
          noiseFreq: new THREE.Vector2(14e-5, 29e-5),
          noiseSpeed: 5e-6
        },
      },
      u_vertDeform: {
        value: {
          incline: Math.sin(0) / Math.cos(0), // 0 is this.angle,
          offsetTop: 0,
          offsetBottom: 0,
          noiseFreq: new THREE.Vector2(3, 4),
          noiseAmp: 320,
          noiseSpeed: 10,
          noiseFlow: 3,
          noiseSeed: 5
        },
      },
      u_baseColor: {
        value: new THREE.Vector3(.5,.5,.5),
      },
      u_waveLayers: {
        value: this.sectionColors.map((_item, e) => ({
          color: new THREE.Vector3(this.sectionColors[e][0], this.sectionColors[e][1], this.sectionColors[e][2]),
          noiseFreq: new THREE.Vector2(2 + e / this.sectionColors.length, 3 + e / this.sectionColors.length),
          noiseSpeed: 11 + .3 * e,
          noiseFlow: 6.5 + .3 * e,
          noiseSeed: this.seed + 10 * e,
          noiseFloor: .1,
          noiseCeil: .63 + .07 * e
        })),
      },
    }

    this.material = new THREE.ShaderMaterial({
      extensions: {
        derivatives: true
      },
      side: THREE.DoubleSide,
      uniforms,
      fragmentShader,
      vertexShader
    })

    this.iridescentMaterial = new THREE.MeshPhysicalMaterial()
  }

  initMesh() {
    this.plane = new THREE.Mesh(this.geometry, this.material)
    this.plane.geometry.rotateX(-Math.PI / 2)
    this.scene.threeScene.add(this.plane)
  }

  resize() {
    //this.renderer.width = window.innerWidth;
  }

  init() {
    this.createUvNormAttribute()
    this.initGradientColors()
    this.initMaterial()
    this.initMesh()
    this.resize()
  }

  public render(e: number) {

    this.time += Math.min(e - this.last, 1e3 / 15);
    this.last = e;

    if (this.material) this.material.uniforms.u_time.value = this.time;

    this.renderer.WebGLRenderer?.render(this.scene.threeScene, this.camera.orthographicCamera)

    requestAnimationFrame((e) => this.render(e))
  }
}
