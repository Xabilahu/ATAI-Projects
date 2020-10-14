import jason.asSyntax.*; 
import jason.environment.Environment;
import jason.environment.grid.GridWorldModel;
import jason.environment.grid.GridWorldView;
import jason.environment.grid.Location;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics;
import java.util.Random;
import java.util.logging.Logger;
import java.util.HashMap;

public class MarsEnv extends Environment {

    public static final int GSize = 9; // grid size
    public static final int GARB  = 16; // garbage code in grid model
	public static final int GARB_PLASTIC  = 32; // garbage code in grid model
	public static final int GARB_PAPER  = 64; // garbage code in grid model

    public static final Term    ns = Literal.parseLiteral("next(slot)");
    public static final Literal g2 = Literal.parseLiteral("garbage(r2)");
	public static final Literal g3 = Literal.parseLiteral("garbage(r3)");
	public static final Literal g4 = Literal.parseLiteral("garbage(r4)");
	
	public static int r1GarbType = 0;

    static Logger logger = Logger.getLogger(MarsEnv.class.getName());

    private MarsModel model;
    private MarsView  view;
	private Literal target = null;
	private HashMap<Integer, Integer> mapGarbToAgent;
	private int[] mapAgentToGarb;
	private int[] burnErrors;

    @Override
    public void init(String[] args) {
		mapGarbToAgent = new HashMap<Integer,Integer>();
		mapGarbToAgent.put(GARB, 1);
		mapGarbToAgent.put(GARB_PLASTIC, 2);
		mapGarbToAgent.put(GARB_PAPER, 3);
		
		mapAgentToGarb = new int[] {0, GARB, GARB_PLASTIC, GARB_PAPER};
		burnErrors = new int[] {0, 0, 0, 0};
		
        model = new MarsModel();
        view  = new MarsView(model);
        model.setView(view);
        updatePercepts();
    }

    @Override
    public boolean executeAction(String ag, Structure action) {
        logger.info(ag+" doing: "+ action);
        try {
            if (action.equals(ns)) {
                model.nextSlot();
            } else if (action.getFunctor().equals("move_towards")) {
				int id = (int)((NumberTerm)action.getTerm(0)).solve();
				int x = (int)((NumberTerm)action.getTerm(1)).solve();
                int y = (int)((NumberTerm)action.getTerm(2)).solve();
                model.moveTowards(id,x,y);
            } else if (action.getFunctor().equals("pick")) {
				int type = (int)((NumberTerm)action.getTerm(0)).solve();
                model.pickGarb(type);
            } else if (action.getFunctor().equals("drop")) {
				int type = (int)((NumberTerm)action.getTerm(0)).solve();
                model.dropGarb(type);
            } else if (action.getFunctor().equals("burn")) {
				int agent = (int)((NumberTerm)action.getTerm(0)).solve();
                model.burnGarb(agent);
            } else {
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        updatePercepts();

        try {
            Thread.sleep(500);
        } catch (Exception e) {}
        informAgsEnvironmentChanged();
        return true;
    }

    /** creates the agents perception based on the MarsModel */
    void updatePercepts() {
        clearPercepts();

        Location r1Loc = model.getAgPos(0);
        Location r2Loc = model.getAgPos(1);
		Location r3Loc = model.getAgPos(2);
		Location r4Loc = model.getAgPos(3);

        Literal pos1 = Literal.parseLiteral("pos(r1," + r1Loc.x + "," + r1Loc.y + ")");
        Literal pos2 = Literal.parseLiteral("pos(r2," + r2Loc.x + "," + r2Loc.y + ")");
		Literal pos3 = Literal.parseLiteral("pos(r3," + r3Loc.x + "," + r3Loc.y + ")");
		Literal pos4 = Literal.parseLiteral("pos(r4," + r4Loc.x + "," + r4Loc.y + ")");
		
        addPercept(pos1);
        addPercept(pos2);
		addPercept(pos3);
		addPercept(pos4);

        if (model.hasObject(GARB, r1Loc) && r1GarbType == 0) {
            addPercept(Literal.parseLiteral("garbage(" + GARB + ",r1)"));
        }
		if (model.hasObject(GARB_PLASTIC, r1Loc) && r1GarbType == 0) {
            addPercept(Literal.parseLiteral("garbage(" + GARB_PLASTIC + ",r1)"));
        }
		if (model.hasObject(GARB_PAPER, r1Loc) && r1GarbType == 0) {
            addPercept(Literal.parseLiteral("garbage(" + GARB_PAPER + ",r1)"));
        }
        if (model.hasObject(GARB, r2Loc)) {
            addPercept(g2);
        }
		if (model.hasObject(GARB_PLASTIC, r3Loc)) {
            addPercept(g3);
        }
		if (model.hasObject(GARB_PAPER, r4Loc)) {
            addPercept(g4);
        }
    }

    class MarsModel extends GridWorldModel {

        public static final int MErr = 2; // max error in pick/burn garb
        int nerr = 0; // number of tries of pick/burn garb

        Random random = new Random(System.currentTimeMillis());

        private MarsModel() {
            super(GSize, GSize, 4);

            // initial location of agents
            try {
                setAgPos(0, random.nextInt(GSize), random.nextInt(GSize));

                Location r2Loc = new Location(random.nextInt(GSize), random.nextInt(GSize));
                setAgPos(1, r2Loc);
				setAgPos(2, random.nextInt(GSize), random.nextInt(GSize));
				setAgPos(3, random.nextInt(GSize), random.nextInt(GSize));
            } catch (Exception e) {
                e.printStackTrace();
            }

            // initial locations of garbage
			for (int i = 0; i < Math.max(1, random.nextInt(GSize * GSize / 2)); i++) {
				int type = (int)Math.pow(2, (random.nextInt(3) + 4));
				int x = random.nextInt(GSize);
				int y = random.nextInt(GSize);
				
				while (hasObject(GARB, x, y) || hasObject(GARB_PAPER, x, y) || hasObject(GARB_PLASTIC, x, y)) {
					x = random.nextInt(GSize);
				    y = random.nextInt(GSize);
				}
				
				add(type, x, y);
			}
        }

        void nextSlot() throws Exception {
            Location r1 = getAgPos(0);
            r1.y++;
            if (r1.y == getHeight()) {
                r1.x ++;
                r1.y = 0;
            }
            if (r1.x == getWidth()) {
                r1.x = 0;
                r1.y = 0;
            }
            // finished searching the whole grid
            setAgPos(0, r1);
            setAgPos(1, getAgPos(1)); // just to draw it in the view
			setAgPos(2, getAgPos(2));
			setAgPos(3, getAgPos(3));
        }

        void moveTowards(int id, int x, int y) throws Exception {
            Location loc = getAgPos(id);
            if (loc.x < x)
                loc.x++;
            else if (loc.x > x)
                loc.x--;
            if (loc.y < y)
                loc.y++;
            else if (loc.y > y)
                loc.y--;
			
			for (int i = 0; i < 4; i++) {
				if (i == id) setAgPos(i, loc);
				else setAgPos(i, getAgPos(i));
			}
        }

        void pickGarb(int type) {
			int incinerator = mapGarbToAgent.get(type);
            if (model.hasObject(type, getAgPos(0)) && !getAgPos(0).equals(getAgPos(incinerator))) {
                if (random.nextBoolean() || nerr == MErr) {
                    remove(type, getAgPos(0));
                    nerr = 0;
					r1GarbType = type;
                } else {
                    nerr++;
                }
            }
        }
        void dropGarb(int type) {
            if (r1GarbType != 0) {
				r1GarbType = 0;
                add(type, getAgPos(0));
            }
        }
        void burnGarb(int agent) {
            if (model.hasObject(mapAgentToGarb[agent], getAgPos(agent))) {
                if (random.nextBoolean() || burnErrors[agent] == MErr) {
                    remove(mapAgentToGarb[agent], getAgPos(agent));
                    burnErrors[agent] = 0;
                } else {
                    burnErrors[agent]++;
                }
            }
        }
    }

    class MarsView extends GridWorldView {

        public MarsView(MarsModel model) {
            super(model, "Mars World", 600);
            defaultFont = new Font("Arial", Font.BOLD, 18); // change default font
            setVisible(true);
            repaint();
        }

        /** draw application objects */
        @Override
        public void draw(Graphics g, int x, int y, int object) {
            drawGarb(g, x, y, object);
        }

        @Override
        public void drawAgent(Graphics g, int x, int y, Color c, int id) {
            String label = "R"+(id+1);
            c = Color.darkGray;
            if (id == 0) {
                c = Color.orange;
                switch (MarsEnv.r1GarbType) {
                    case MarsEnv.GARB:
						label += " - O";
						break;
					case MarsEnv.GARB_PLASTIC:
						label += " - P";
						break;
					case MarsEnv.GARB_PAPER:
						label += " - C";
						break;
				}
            }else if (id == 2) c = Color.yellow;
			 else if (id == 3) c = Color.blue;
            super.drawAgent(g, x, y, c, -1);
            if (id == 0 || id == 2) {
                g.setColor(Color.black);
            } else {
                g.setColor(Color.white);
            }
            super.drawString(g, x, y, defaultFont, label);
            //repaint();
        }

        public void drawGarb(Graphics g, int x, int y, int type) {
            Color c = null, fc = null;
			String s = "";
			switch(type){
				case MarsEnv.GARB:
					c = Color.darkGray;
					fc = Color.white;
					s = " - O";
					break;
				case MarsEnv.GARB_PLASTIC:
					c = Color.yellow;
					fc = Color.black;
					s = " - P";
					break;
				case MarsEnv.GARB_PAPER:
					c = Color.blue;
					fc = Color.white;
					s = " - C";
					break;
			}
			
			g.setColor(c);
			g.fillRect(x * cellSizeW + 1, y * cellSizeH+1, cellSizeW-1, cellSizeH-1);
			g.setColor(Color.black);
			g.drawRect(x * cellSizeW + 2, y * cellSizeH+2, cellSizeW-4, cellSizeH-4);
            g.setColor(fc);
            drawString(g, x, y, defaultFont, "G" + s);
		}

    }
}
