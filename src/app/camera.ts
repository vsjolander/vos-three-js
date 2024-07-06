import * as THREE from 'three'

export default class Camera {
  public perspectiveCamera
  public orthographicCamera
  constructor() {
    console.log('Camera init')
    this.perspectiveCamera = new THREE.PerspectiveCamera( 30, window.innerWidth/window.innerHeight, 1, 1000 );
    this.orthographicCamera = new THREE.OrthographicCamera( 480 / -2, 480 / 2, 640 / 2, 640 / - 2, -2000, 2000 );
  }
}
