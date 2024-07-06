import * as THREE from 'three'

export default class Scene {
  public threeScene
  constructor() {
    console.log('Scene init')
    this.threeScene = new THREE.Scene();
  }
}
