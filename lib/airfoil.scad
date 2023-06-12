// partly ripped from https://github.com/ErroneousBosch/OpenSCAD_airfoil/blob/master/airfoil.scad

$airfoil_fn = 120;
$close_airfoils = true;

  function foil_y(x, c, t) = 
(5*t*c)*( ( 0.2969 * sqrt(x/c) ) - ( 0.1260*(x/c) ) - ( 0.3516*pow((x/c),2) ) + ( 0.2843*pow((x/c),3) ) - ( ( $close_airfoils ? 0.1036 : 0.1015)*pow((x/c),4) ) ); //NACA symetrical airfoil formula
  function camber(x,c,m,p) = ( x <= (p * c) ? 
    ( ( (c * m)/pow( p, 2 ) ) * ( ( 2 * p * (x / c) ) - pow( (x / c) , 2) ) ) :
    ( ( (c * m)/pow((1 - p),2) ) * ( (1-(2 * p) ) + ( 2 * p * (x / c) ) - pow( (x / c) ,  2)))
    );
  function theta(x,c,m,p) = ( x <= (p * c) ? 
    atan( ((m)/pow(p,2)) * (p - (x / c)) ) :
    atan( ((m)/pow((1 - p),2)) * (p - (x / c))  ) 
    );
  function camber_y(x,c,t,m,p, upper=true) = ( upper == true ?
  ( camber(x,c,m,p) + (foil_y(x,c,t) * cos( theta(x,c,m,p) ) ) ) :
  ( camber(x,c,m,p) - (foil_y(x,c,t) * cos( theta(x,c,m,p) ) ) )
  );
  function camber_x(x,c,t,m,p, upper=true) = ( upper == true ?
  ( x - (foil_y(x,c,t) * sin( theta(x,c,m,p) ) ) ) :
  ( x + (foil_y(x,c,t) * sin( theta(x,c,m,p) ) ) )
  );

module mcl_poly (c = 100, naca = 0015, stroke_width = 1) {
  $close_airfoils = ($close_airfoils != undef) ? $close_airfoils : false;
  $airfoil_fn = ($airfoil_fn != undef) ? $airfoil_fn : 100;
  res = c/$airfoil_fn; //resolution of foil poly
  t = ((naca%100)/100); //establish thickness/length ratio
  m = ( (floor((((naca-(naca%100))/1000))) /100) );
  p = ((((naca-(naca%100))/100)%10) / 10);

  points_upper = ( m == 0 || p == 0) ?
  [for (i = [0:res:c]) let (x = i, y = stroke_width/2 ) [x,y]] :
  [for (i = [0:res:c]) let (x = i, y = camber(i,c,m,p) + stroke_width/2) [x,y]];

  points_lower = ( m == 0 || p == 0) ?
  [for (i = [c:-1*res:0]) let (x = i, y = -stroke_width/2 ) [x,y]] :
  [for (i = [c:-1*res:0]) let (x = i, y = camber(i,c,m,p) - stroke_width/2) [x,y]];

  polygon(concat(points_upper,points_lower)); //draw poly
}

module airfoil_poly (c = 100, naca = 0015) {
  $close_airfoils = ($close_airfoils != undef) ? $close_airfoils : false;
  $airfoil_fn = ($airfoil_fn != undef) ? $airfoil_fn : 100;
  res = c/$airfoil_fn; //resolution of foil poly 
  t = ((naca%100)/100); //establish thickness/length ratio
  m = ( (floor((((naca-(naca%100))/1000))) /100) );
  p = ((((naca-(naca%100))/100)%10) / 10);
    
  // points have to be generated with or without camber, depending. 
    points_u = ( m == 0 || p == 0) ?
     [for (i = [0:res:c]) let (x = i, y = foil_y(i,c,t) ) [x,y]] :
     [for (i = [0:res:c]) let (x = camber_x(i,c,t,m,p), y = camber_y(i,c,t,m,p) ) [x,y]] ;
    
    points_l = ( m == 0 || p == 0) ?
     [for (i = [c:-1*res:0]) let (x = i, y = foil_y(i,c,t) * -1 ) [x,y]] :
     [for (i = [c:-1*res:0]) let (x = camber_x(i,c,t,m,p,upper=false), y = camber_y(i,c,t,m,p, upper=false) ) [x,y]] ;    
 
   polygon(concat(points_u,points_l)); //draw poly
}
