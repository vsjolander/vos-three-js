import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
export default class Controls {
  public orbital
  constructor(camera: any, canvas: HTMLCanvasElement) {
    this.orbital = new OrbitControls( camera, canvas );
  }
}
