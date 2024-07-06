import * as THREE from 'three'

export default class Renderer {
  public WebGLRenderer

  constructor(canvas: HTMLCanvasElement, width: number = 640, height: number = 480) {
    console.log('Renderer init')
    if (canvas) {
      this.WebGLRenderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true })
      this.WebGLRenderer.setSize(width, height)
      this.WebGLRenderer.setClearColor(0xeeeeee, 1)
    }
  }
}
