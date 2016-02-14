/* OpenProcessing Tweak of *@*http://www.openprocessing.org/sketch/247016*@* */
/* !do not delete the line above, required for linking your tweak if you upload again */
/* @pjs preload="meteor0.gif"; */
/* @pjs preload="meteor1.gif"; */
/* @pjs preload="meteor2.gif"; */
/* @pjs preload="bonus.gif"; */
/* @pjs preload="ship.png"; */
/* @pjs preload="flame.png"; */
/* @pjs preload="explosion0.png"; */
/* @pjs preload="explosion1.png"; */
/* @pjs preload="explosion2.png"; */
/* @pjs preload="explosion3.png"; */
/* @pjs preload="explosion4.png"; */
/* @pjs preload="explosion5.png"; */
/* @pjs preload="explosion6.png"; */
/* @pjs preload="explosion7.png"; */
/* @pjs preload="explosion8.png"; */


final int GAME_OVER_STATE = 0;
final int PLAYING_STATE = 1;
final int PAUSED_STATE = 2;

int currentState = GAME_OVER_STATE;

Game game;
KeyboardMgr keyboardMgr;
Info infos;
float margin = 20;
Boolean changingLevel = false;
Boolean losingLife = false;
int level, score, lives;

void setup() {
  size(650, 650, P2D);
  imageMode(CENTER);
  keyboardMgr = new KeyboardMgr();
  game = new Game();
}

void draw() {
  if (currentState == PLAYING_STATE) {
    if (game.update()) {//game over
      soundGameOver();
      currentState = GAME_OVER_STATE;
    }
  }
  if (currentState == GAME_OVER_STATE) {
    background(0);
    game.displayInfo();
    fill(240, 10, 10);
    text("Game Over", width/2-80, height/2-42);
    fill(10, 240, 10);
    text("Press g to start the game", width/2-90, height/2-14);
    fill(120, 120, 250);
    text("LEFT: turn left", width/2-80, height/2+14);
    text("RIGHT: turn right", width/2-80, height/2+28);
    text("UP: move forward", width/2-80, height/2+42);
    text("DOWN: shield", width/2-80, height/2+56);
    text("CLICK/ALT/CONTROL: fire", width/2-80, height/2+70);
    text("P: pause game", width/2-80, height/2+84);
  }
}

void keyPressed()
{
  if (key == CODED) {
    keyboardMgr.keyDown(keyCode);
  } else {
    switch(key) {
    case 'p':
      if (currentState == PLAYING_STATE) {
        currentState = PAUSED_STATE;
        //println("game paused");
      } else if (currentState == PAUSED_STATE) {
        currentState = PLAYING_STATE;
        //println("game resumed");
      }
      break;
    case 'g':
      if (currentState == GAME_OVER_STATE) {
        currentState = PLAYING_STATE;
        soundGameStart();
        game = new Game();
        //println("new game!");
      }
      break;
    }
  }
}

void keyReleased()
{
  if (key == CODED) {
    keyboardMgr.keyUp(keyCode);
  }
}

void mousePressed(){
  keyboardMgr.keyDown(ALT);
}

void mouseReleased(){
  keyboardMgr.keyUp(ALT);
}

class Bonus {
  final int MISSILE_LONG_FIRE = 0;
  final int MISSILE_LONG_LIFE = 1;
  final int MISSILE_TRIPLE = 2;
  final int SHIP_STABILIZER = 3;
  final int SHIELD_SUPPLY = 4;

  final int w = 28, h = 20;
  final int displayDuration = 10000;//10 seconds
  final float maxSpeed = 2;
  
  PImage img = loadImage("bonus.gif");
  
  Ship ship;
  Info infos;
  Missiles missiles;

  Boolean missileLongFire = false;
  Boolean missileLongLife = false;
  Boolean missileTriple = false;
  Boolean stabilizer = false;

  Boolean bonusDisplayed = false;
  Boolean bonusDisplay = false;
  int displayTime;

  PVector pos, speed;
  float theta;
  
  Bonus(Ship p_ship, Missiles p_missiles, Info p_infos){
    ship = p_ship;
    missiles = p_missiles;
    infos = p_infos;
  } 

  void addBonus(int bonusType) {
    switch(bonusType) {
    case MISSILE_LONG_FIRE:
      //println("MISSILE_LONG_FIRE");
      missileLongFire = true;
      break;
    case MISSILE_LONG_LIFE:
      //println("MISSILE_LONG_LIFE");
      missileLongLife = true;
      break;
    case MISSILE_TRIPLE:
      //println("MISSILE_TRIPLE");
      missileTriple = true;
      break;
    case SHIP_STABILIZER:
      //println("SHIP_STABILIZER");
      stabilizer = true;
      break;
    case SHIELD_SUPPLY:
      ship.addShield();
      break;
    default:
      //println("unknown bonus :-(");
      break;
    }
  }

  void init() {
    missileLongFire = false;
    missileLongLife = false;
    missileTriple = false;
    stabilizer = false;
    ship.initShield();
  }

  void update() {
    if (bonusDisplay) {
      displayBonus();
    } else if (!bonusDisplayed && random(1) < .02) {
      pos = new PVector(random(width), random(height));
      speed = new PVector(random(-maxSpeed, maxSpeed), random(-maxSpeed, maxSpeed));  
      theta = random(3.14);
      bonusDisplay = true;
      bonusDisplayed = true;
      displayTime = millis();
    }
  }

  void displayBonus() {
    if (millis() - displayTime > displayDuration) {
      bonusDisplay = false;
    } else {
      theta += .03;
      pos.add(speed);
      if (pos.x < -margin)
        pos.x = width+margin;
      else if (pos.x > width+margin)
        pos.x = -margin;
      if (pos.y < -margin)
        pos.y = height+margin-infos.h;
      else if (pos.y > height+margin-infos.h)
        pos.y = -margin;

//      fill(160, 0, 0);
//      stroke(230, 0, 0);
//      rectMode(CENTER);
      pushMatrix();
      translate(pos.x, pos.y);
      rotate(theta);
//      rect(0, 0, w, h);
      image(img, 0, 0);
      popMatrix();
    }
  }

  void checkCollisions() {
    if (bonusDisplay) {
      //check missile-bonus collision
      if (missiles.bonusCollision()) {
        soundBonusExplosion();
        bonusDisplay = false;
        return;
      }

      //check ship-bonus collision
      if (PVector.dist(pos, ship.pos) < (w+h+ship.w+ship.h)/4) {
        //println("bonus !"); 
        addBonus(int(random(0, 5)));      
        bonusDisplay = false;
        infos.addScoreLevel(500);
        soundBonus();
      }
    }
  }

  void goToNextLevel() {
    bonusDisplayed = false;
    bonusDisplay = false;
  }
}
class Game {
  Ship ship;
  Missiles missiles;
  Meteors meteors;
  Bonus bonus;
  Stars stars;

  Game() {
    lives = 3;
    level = 1;
    score = 0;
    ship = new Ship();
    missiles = new Missiles();
    meteors = new Meteors();
    infos = new Info();
    bonus = new Bonus(ship, missiles, infos);
    stars = new Stars();
  }

  Boolean update() {//returns true if game is over
    background(0);
    if (currentState == PLAYING_STATE && !changingLevel) {
      stars.display();
    }
    if (!changingLevel) {
      missiles.update();

      meteors.update();

      bonus.update();

      if (losingLife) {
        ship.init();
        bonus.init();
        keyboardMgr.init();
        losingLife = false;
      }
      ship.update();

      missiles.checkMeteors();

      if (!losingLife) {
        bonus.checkCollisions();
        losingLife = meteors.checkShipCollision();
        if (losingLife) {
          lives--;
          if (lives == 0) {
            //println("game over");
            return true;
          } else {
            soundShipExplosion();
          }
        }
      }
    }

    if (infos.display(true)) {//3-2-1 timer is elapsed
      ship.init();
      missiles = new Missiles();
      meteors = new Meteors();
      changingLevel = false;
      level++;
    }

    if (meteors.getCount() == 0 && !changingLevel) {
      //println("level cleared");
      goToNextLevel();
    }

    return false;
  }

  void displayInfo() {
    infos.display(false);
  }

  void goToNextLevel() {
//    soundLevelCleared();
    changingLevel = true;
    infos.goToNextLevel();
    bonus.goToNextLevel();
  }

  void addLife() {
    lives ++;
  }
}

class Info {
  final int h = 20;
  final int newLifeStep = 50000;
  int scoreLevel = 2000;
  int score = 0;
  int startChangeLevel;
  int startLevel = millis();

  void addScore(int p_value) {
    int prevScore = score;
    score += p_value;
    if(floor(prevScore/newLifeStep) < floor(score/newLifeStep)){
      game.addLife();
    }
  }
  
  void addScoreLevel(int p_value) {
    scoreLevel += p_value;
  }

  Boolean display(Boolean p_update) {//returns true if the changing level timer is complete
    rectMode(CORNER);
    noStroke();
    fill(10);
    rect(0, height - h, width, h);//background

    stroke(255);
    line(0, height - h, width, height - h);
    fill(255, 255, 0);
    text("level: " + level, 10, height - 7);
    fill(0, 255, 255);
    text("lives: " + lives, 80, height - 7);
    
    noStroke();
    fill(255);
    rect(140, height-14, 44, 9);
    fill(255, 120, 120);
    rect(141, height-13, map(game.ship.shieldValue, 0, game.ship.maxShieldValue, 0, 42), 7);
    
    fill(255, 0, 255);
    text("score: " + score, 210, height - 7);
    fill(0, 255, 0);
    text("level score: " + scoreLevel, 310, height - 7);
    
    noStroke();
    if(game.bonus.stabilizer){
        fill(45, 190, 12);
        rect(470, height - 14, 9, 9);
    }
    if(game.bonus.missileLongLife){
        fill(245, 190, 12);
        rect(485, height - 14, 9, 9);
    }
    if(game.bonus.missileLongFire){
        fill(205, 0, 52);
        rect(500, height - 14, 9, 9);
    }
    if(game.bonus.missileTriple){
        fill(115, 170, 52);
        rect(515, height - 14, 9, 9);
    }

    if(p_update){
      int t = millis();
      if (changingLevel) {
        int dt = t - startChangeLevel;
        if (dt > 3000) {
          addScore(scoreLevel);
          scoreLevel = 2000;
          startLevel = t;
          changingLevel = false;
          return true;
        } else if (dt > 2000) {
          displayTransition("1");
        } else if (dt > 1000) {
          displayTransition("2");
        } else {
          displayTransition("3");
        }
      } else if(losingLife){
        
      } else if ((scoreLevel > 0) && (t - startLevel > 1500)) {
        scoreLevel = max(0, scoreLevel - 20);
        startLevel = t;
      }
    }
    return false;
  }

  void goToNextLevel() {
    startChangeLevel = millis();
  }

  void displayTransition(String t) {
    fill(0, 255, 0);
    text("level " + level + " cleared", width/2 - 60, height/2 - 40);
    text("Prepare for level " + (level+1), width/2 - 60, height/2 - 20);
    fill(255, 0, 0);
    text(t, width/2, height/2);
  }
}
class KeyboardMgr {
  Boolean left = false;
  Boolean right = false;
  Boolean up = false;
  Boolean fire = false;
  Boolean fireUp = true;
  Boolean longFire = false;

  void keyDown(int p_key) {
    switch(p_key) {
    case LEFT:
      left = true;
      break;
    case RIGHT:
      right = true;
      break;
    case UP:
      up = true;
      game.ship.changeEngineValue(true);
      break;
    case DOWN:
      game.ship.changeShieldValue(true);
      break;
    case CONTROL:
    case ALT:
      if (game.bonus.missileLongFire) 
        longFire = true;
      else if (fireUp) {//single missile not launched yet
        fire = true;
        fireUp = false;
      }
      break;
    }
  }

  void keyUp(int p_key) {
    switch(p_key) {
    case LEFT:
      left = false;
      break;
    case RIGHT:
      right = false;
      break;
    case UP:
      up = false;
      game.ship.changeEngineValue(false);
      break;
    case DOWN:
      game.ship.changeShieldValue(false);
      break;
    case CONTROL:
    case ALT:
      fire = false;
      longFire = false;
      fireUp = true;
      break;
    }
  }

  void init() {
    fireUp = false;
    longFire = false;
  }
}

class Meteor {

  final float maxSpeed = 2.5;
  PVector pos, speed;
  float diam;
  int type = int(random(3));
  int value;
  int col = color(random(255), random(255), random(255));
  PImage img;
  PImage[] deathImgs;
  float theta = 0, thetaSpeed = random(-.14, .14);
  Boolean dead = false;
  int deathTimer = 0;

  Meteor(PVector p_pos, int p_type, float p_diam, int p_value, PImage p_img, PImage[] p_imgs) {
    if (p_pos != null)
      pos = p_pos.get();
    else
      pos = new PVector(random(width), random(height));

    speed = new PVector(random(-maxSpeed, maxSpeed), random(-maxSpeed, maxSpeed));  
    type = p_type;
    diam = p_diam;
    value = p_value;
    img = p_img;
    deathImgs = p_imgs;
  }

  void update() {
    theta += thetaSpeed;
    pos.add(speed);
    if (pos.x < -margin)
      pos.x = width+margin;
    else if (pos.x > width+margin)
      pos.x = -margin;
    if (pos.y < -margin)
      pos.y = height+margin-infos.h;
    else if (pos.y > height+margin-infos.h)
      pos.y = -margin;

    //    noStroke();
    //    stroke(240);
    //    fill(130, 130, 255);
    //    fill(col);
    //    ellipse(pos.x, pos.y, diam, diam);
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(theta);
    image(img, 0, 0, diam, diam);
    popMatrix();
  }
  
  Boolean updateDeath(){
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(theta);
    image(deathImgs[int(deathTimer/2)], 0, 0);
    popMatrix();
    deathTimer++;
    return deathTimer > 8 * 2;
  }

  Boolean checkCollisionShip() {
    if (game.ship.shieldOn || game.ship.initShieldOn) {
      return (PVector.dist(pos, game.ship.pos) < (game.ship.shieldRad+diam)/2);
    } else {
      return (PVector.dist(pos, game.ship.pos) < (game.ship.w+game.ship.h+diam)/4);
    }
  }
}

class Meteors {
  final PImage[] imgs = {
    loadImage("meteor0.gif"),
    loadImage("meteor1.gif"),
    loadImage("meteor2.gif")
  };
  final PImage[] deathImgs = {
    loadImage("explosion0.png"),
    loadImage("explosion1.png"),
    loadImage("explosion2.png"),
    loadImage("explosion3.png"),
    loadImage("explosion4.png"),
    loadImage("explosion5.png"),
    loadImage("explosion6.png"),
    loadImage("explosion7.png"),
    loadImage("explosion8.png")
  };
  
  final float[] diams = {
    13, 26, 40
  };
  final int[] values = {
    500, 200, 50
  };
  ArrayList<Meteor> meteorsArray;
  ArrayList<Meteor> deads;
  int nb;

  Meteors() {
    nb = level + int(random(1, 4));
    meteorsArray = new ArrayList<Meteor>();
    deads = new ArrayList<Meteor>();
    for ( int i = 0; i < nb; i++ ) {
      meteorsArray.add(new Meteor(null, 2, diams[2], values[2], imgs[2], deathImgs));
    }
  }

  void update() {
    nb = meteorsArray.size();
    for ( int i = deads.size()-1; i > -1; i-- ) {
      if(deads.get(i).updateDeath()){
         deads.remove(i); 
      }
    }
    for ( int i = nb-1; i > -1; i-- ) {
      meteorsArray.get(i).update();
    }
  }

  void collision(int hitMeteorIdx) {
    Meteor hitMeteor = meteorsArray.get(hitMeteorIdx);
    int meteorType = hitMeteor.type;
    PVector meteorPos = hitMeteor.pos.get();
    infos.addScore(hitMeteor.value);
    meteorsArray.remove(hitMeteorIdx);
    switch(meteorType) {
    case 0://small meteor: do nothing
      deads.add(hitMeteor);
      break;
    case 1://medium meteor: add 1 to 3 small meteors
    case 2://large meteor: add 1 to 3 medium meteors
      int nbToAdd = int(random(1, 4));
      //println("nbToAdd: " + nbToAdd);
      meteorType--;
      for (int j = 1; j < nbToAdd+1; j ++) {
        meteorsArray.add(new Meteor(meteorPos, meteorType, 
                          diams[meteorType], values[meteorType], imgs[meteorType], deathImgs));
      }
      break;
    }
    soundMeteorExplosion();
    //println("nb meteors: " + meteorsArray.size());
  }

  Boolean checkShipCollision() {
    int nb = meteorsArray.size();
    for ( int i = nb-1; i > -1; i-- ) {
      Meteor m = meteorsArray.get(i);
      if (m.checkCollisionShip()) {
        //println("ship hit! " + random(1));
        collision(i);
        return !(game.ship.shieldOn || game.ship.initShieldOn);
      }
    }
    return false;
  }

  int getCount() {
    return meteorsArray.size();
  }
}
class Missile {
  PVector pos, speed = new PVector(0, 0);
  int age = 0;
  int ageMax;
  final float speedInitial = 3, rad = 5;
  final float tripleAngle = .21;
  
  Missile(float angle, int p_ageMax){
    ageMax = p_ageMax;
    pos = game.ship.getNosePosition();//pos.get();
    float theta = game.ship.theta - HALF_PI;
    theta += angle*tripleAngle;
    speed = new PVector(cos(theta), sin(theta));
    speed.mult(speedInitial);
    PVector shipSpeed = game.ship.speed.get();
    speed.add(shipSpeed);
    soundMissile();
  }
  
  Boolean update(){
    pos.add(speed);
    if (pos.x < -margin)
      pos.x = width+margin;
    else if (pos.x > width+margin)
      pos.x = -margin;
    if (pos.y < -margin)
      pos.y = height+margin-infos.h;
    else if (pos.y > height+margin-infos.h)
      pos.y = -margin;
      
    noStroke();
    fill(0, 0, 255);
    ellipse(pos.x, pos.y, rad, rad);
    return (age++ > ageMax);
  }
  
  Boolean checkColisionMeteor(Meteor meteor){
    PVector meteorPos = meteor.pos;
    float dx = meteorPos.x - pos.x;
    float dy = meteorPos.y - pos.y;
    float meteorRad = meteor.diam;
    return (dx*dx + dy*dy < (rad+meteorRad)*(rad+meteorRad)/4);
  }
  
  Boolean checkColisionBonus(){
    return (PVector.dist(pos, game.bonus.pos) < (game.bonus.w+game.bonus.h+rad)/4);
  }
}
class Missiles {
  final int longFireStep = 5;//space the long fire missiles
  int[] maxAges = new int[2];
  int nb;
  ArrayList<Missile> missilesArray = new ArrayList<Missile>();

  Missiles() {
    maxAges[0] = 80;
    maxAges[1] = 115;
  }

  void update() {
    nb = missilesArray.size();

    int nbMax = game.bonus.missileLongFire ? 80 : 20;
    if ( (keyboardMgr.fire || ( keyboardMgr.longFire && (frameCount % longFireStep == 0))) && (nb < nbMax)) {
      int missileMaxAge = game.bonus.missileLongLife ? maxAges[1] : maxAges[0];
      missilesArray.add(new Missile(0, missileMaxAge));
      if (game.bonus.missileTriple) {
        missilesArray.add(new Missile(-1, missileMaxAge));
        missilesArray.add(new Missile(1, missileMaxAge));
      }
      nb ++;
      if (keyboardMgr.fire) {
        keyboardMgr.fire = false;
      }
    }

    for ( int i = nb-1; i > -1; i-- ) {
      if (missilesArray.get(i).update()) {
        missilesArray.remove(i);
      }
    }
  }

  void checkMeteors() {
    nb = missilesArray.size();
    ArrayList<Meteor> meteorsArray = game.meteors.meteorsArray;
    for ( int i = nb-1; i > -1; i-- ) {
      int nbMeteors = meteorsArray.size();
      for ( int j = nbMeteors-1; j > -1; j-- ) {
        Meteor meteor = meteorsArray.get(j);
        if (missilesArray.get(i).checkColisionMeteor(meteor)) {
          //there was a collision between the missile and the meteor
          missilesArray.remove(i);
          game.meteors.collision(j);
          break;
        }
      }
    }
  }

  Boolean bonusCollision() {
    nb = missilesArray.size();

    for ( int j = nb-1; j > -1; j-- ) {
      if (missilesArray.get(j).checkColisionBonus()) {
        missilesArray.remove(j);
        return true;
      }
    }
    return false;
  }
}
class Ship {
  final float MAX_SPEED = 10;
  final float ACCELERATION = .13;
  final float VISCOSITY = .975;
  final float w = 20, h = 32;
  PVector pos, speed;
  float theta;
  Boolean shieldOn = false, initShieldOn = false, playShieldSound = true;
  float shieldValue = 10, maxShieldValue = 20, shieldRad = 38;
  int shieldTimer;
  PImage img = loadImage("ship.png");
  PImage flameImg = loadImage("flame.png");
  PVector nose = new PVector(0, -18);
  Boolean engineOn = false;

  Ship() {
    init();
  }

  void update() {
    processKeys();

    if (game.bonus.stabilizer && !engineOn) {
      speed.mult(VISCOSITY);
    }

    if (speed.mag() > MAX_SPEED) {
      speed.normalize();
      speed.mult(MAX_SPEED);
    }

    pos.add(speed); 
    if (pos.x < -margin)
      pos.x = width+margin;
    else if (pos.x > width+margin)
      pos.x = -margin;
    if (pos.y < -margin)
      pos.y = height+margin-infos.h;
    else if (pos.y > height+margin-infos.h)
      pos.y = -margin;

    rectMode(CENTER);
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(theta);
    if(engineOn){
       image(flameImg, 0, 20); 
    }
    image(img, 0, 0);
    if ((shieldOn && shieldValue > 0) || initShieldOn) {
      if (!initShieldOn) {
        shieldValue = max(0, shieldValue - .035);
      } else if (millis() - shieldTimer > 3000) {
        initShieldOn = false;
      }
      noFill();
      stroke(230, 230, 0);
      ellipse(0, 0, shieldRad, shieldRad);
    } else {
      shieldOn = false;
    }
    popMatrix();
  }

  void processKeys() {
    if (keyboardMgr.left)
      theta -= .1;
    if (keyboardMgr.right)
      theta += .1;
    if (engineOn) {
      speed.x += ACCELERATION * cos(theta - HALF_PI);
      speed.y += ACCELERATION * sin(theta - HALF_PI);
    }
  }

  void init() {
    pos = new PVector(width/2, height/2);
    speed = new PVector(0, 0);
    theta = 0;
    initShieldOn = true;
    shieldTimer = millis();
  }

  void initShield() {
    shieldValue = 10;
  }

  void addShield() {
    //println("addShield");
    shieldValue = min(shieldValue+maxShieldValue/2, maxShieldValue);
  }

  void changeShieldValue(Boolean p_shieldOn) {
    if (p_shieldOn && !shieldOn && shieldValue > 0) {
      soundShield();
    }
    shieldOn = p_shieldOn;
  }
  
  void changeEngineValue(Boolean p_engineOn){
    engineOn = p_engineOn;
    soundEngine(engineOn);
  }
  
  PVector getNosePosition(){
    float x, y;
    x = nose.x * cos(theta) - nose.y * sin(theta) + pos.x;
    y = nose.x * sin(theta) + nose.y * cos(theta) + pos.y;
    return new PVector(x, y);
  }
}

class Stars {
  int nbStars;
  PVector[] stars;
  int[] colors;

  Stars() {
    nbStars = int(sqrt(width*(height-infos.h)));
    stars = new PVector[nbStars];
    colors = new int[nbStars];
    for (int i = 0; i < nbStars; i++) {
      stars[i] = new PVector(random(width), random(height-infos.h));
      colors[i] = color(random(255), random(255), random(255));
    }
  }
 
  void display() {
    for (int i = 0; i < stars.length; i++) {
      stroke(colors[i]);
      point(stars[i].x, stars[i].y);
    }
  }
}

