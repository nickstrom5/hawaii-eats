"""Known chain brands in Hawaii: regex on normalized name -> brand label.

Adapted from id-eats/pipeline/brands.py; Idaho and Utah chains dropped, Hawaii's own chains added.
"""
import re

BRANDS = [
    ("Dunkin'", r"^DUNKIN"), ("Subway", r"^SUBWAY"), ("McDonald's", r"^MC ?DONALDS"), ("Starbucks", r"^STARBUCK"),
    ("Jimmy John's", r"^JIMMY JOHN"), ("Burger King", r"^BURGER KING"), ("Taco Bell", r"^TACO BELL"),
    ("Potbelly", r"^POTBELLY"), ("Wingstop", r"^WING ?STOP"), ("Chipotle", r"^CHIPOTLE"), ("Popeyes", r"^POPEYE"),
    ("Wendy's", r"^WENDYS"), ("Panda Express", r"^PANDA EXPRESS"), ("White Castle", r"^WHITE CASTLE"),
    ("Chick-fil-A", r"^CHICK FIL"), ("Domino's", r"^DOMINO"), ("Jersey Mike's", r"^JERSEY MIKE"),
    ("Panera Bread", r"^PANERA"), ("Jet's Pizza", r"^JETS PIZZA"), ("Little Caesars", r"^LITTLE CAESAR"),
    ("Papa John's", r"^PAPA JOHN"), ("KFC", r"^KFC|^KENTUCKY FRIED"), ("Tropical Smoothie Cafe", r"^TROPICAL SMOOTHIE"),
    ("Buffalo Wild Wings", r"^BUFFALO WILD"), ("Five Guys", r"^FIVE GUYS"), ("Raising Cane's", r"^RAISING CANE"),
    ("Portillo's", r"^PORTILLO"), ("Auntie Anne's", r"^AUNTIE ANNE"), ("Qdoba", r"^QDOBA"),
    ("Noodles & Company", r"^NOODLES (?:AND )?CO(?:MPANY)?\b"), ("Smoothie King", r"^SMOOTHIE KING"), ("Firehouse Subs", r"^FIREHOUSE SUB"),
    ("IHOP", r"^IHOP"), ("Denny's", r"^DENNYS"), ("Sonic", r"^SONIC DRIVE|^SONIC$"), ("Insomnia Cookies", r"^INSOMNIA COOKIE"),
    ("Crumbl", r"^CRUMBL"), ("Dairy Queen", r"^DAIRY QUEEN|^DQ GRILL|^DQ$"), ("Baskin-Robbins", r"^BASKIN"), ("Krispy Kreme", r"^KRISPY KREME"),
    ("Chuck E. Cheese", r"^CHUCK E CHEESE"), ("Rosati's", r"^ROSATI"), ("Nothing Bundt Cakes", r"^NOTHING BUNDT"),
    ("Hooters", r"^HOOTERS"), ("Cheesecake Factory", r"^CHEESECAKE FACTORY"), ("P.F. Chang's", r"^P ?F CHANG"), ("Maggiano's", r"^MAGGIANO"),
    ("Ruth's Chris", r"^RUTHS CHRIS"), ("Morton's", r"^MORTONS THE STEAK|^MORTONS STEAK"), ("Steak 'n Shake", r"^STEAK N SHAKE"),
    ("Applebee's", r"^APPLEBEE"), ("Chili's", r"^CHILIS"), ("Olive Garden", r"^OLIVE GARDEN"), ("Red Lobster", r"^RED LOBSTER"),
    ("Jamba", r"^JAMBA"), ("Cinnabon", r"^CINNABON"), ("Pizza Hut", r"^PIZZA HUT"), ("Arby's", r"^ARBYS"),
    ("Checkers", r"^CHECKERS DRIVE|^CHECKERS AND RALLY|^CHECKERS$"), ("MOD Pizza", r"^MOD PIZZA"), ("Tim Hortons", r"^TIM HORTON"),
    ("Peet's Coffee", r"^PEETS"), ("Colectivo", r"^COLECTIVO"), ("Cava", r"^CAVA$|^CAVA (?:MEDITERRANEAN|GRILL)"), ("Blaze Pizza", r"^BLAZE PIZZA"),
    # national chains common in Colorado, and Colorado's own
    ("Culver's", r"^CULVER"), ("Taco John's", r"^TACO JOHN"), ("Caribou Coffee", r"^CARIBOU COFFEE|^CARIBOU$"),
    ("Scooter's Coffee", r"^SCOOTERS COFFEE"), ("Dutch Bros", r"^DUTCH BRO"), ("7 Brew", r"^7 BREW"), ("The Human Bean", r"^(?:THE )?HUMAN BEAN"),
    ("Black Rock Coffee", r"^BLACK ROCK COFFEE"), ("Ziggi's Coffee", r"^ZIGGIS"), ("Dazbog Coffee", r"^DAZBOG"),
    ("Texas Roadhouse", r"^TEXAS ROADHOUSE"), ("Famous Dave's", r"^FAMOUS DAVE"), ("Red Robin", r"^RED ROBIN"),
    ("Freddy's", r"^FREDDYS FROZEN|^FREDDYS STEAKBURGER"), ("Papa Murphy's", r"^PAPA MURPH"), ("Marco's Pizza", r"^MARCOS PIZZA"),
    ("Cracker Barrel", r"^CRACKER BARREL"), ("Outback Steakhouse", r"^OUTBACK STEAK"), ("LongHorn Steakhouse", r"^LONGHORN STEAK"),
    ("Cold Stone Creamery", r"^COLD STONE"), ("Golden Corral", r"^GOLDEN CORRAL"),
    ("Old Chicago", r"^OLD CHICAGO$|^OLD CHICAGO (?:PASTA|PIZZA|TAPROOM)"), ("Rock Bottom", r"^ROCK BOTTOM"),
    ("Einstein Bros. Bagels", r"^EINSTEIN BRO"), ("Quiznos", r"^QUIZNO"), ("Fazoli's", r"^FAZOLI"), ("Dickey's Barbecue Pit", r"^DICKEYS"),
    ("HuHot Mongolian Grill", r"^HUHOT"), ("Blimpie", r"^BLIMPIE"), ("Dave's Hot Chicken", r"^DAVES HOT CHICKEN"), ("Sbarro", r"^SBARRO"),
    ("Great Harvest", r"^GREAT HARVEST"), ("Teriyaki Madness", r"^TERIYAKI MADNESS"), ("First Watch", r"^FIRST WATCH"),
    ("TGI Fridays", r"^TGI FRIDAY"), ("Mooyah", r"^MOOYAH"), ("Charleys Cheesesteaks", r"^CHARLEYS"), ("Smashburger", r"^SMASHBURGER"),
    ("Hunt Brothers Pizza", r"^HUNT BROTHERS"), ("Hot Stuff Pizza", r"^HOT STUFF"), ("Krispy Krunchy Chicken", r"^KRISPY KRUNCHY"),
    ("Cheba Hut", r"^CHEBA HUT"), ("MrBeast Burger", r"^MR ?BEAST"), ("It's Just Wings", r"^ITS JUST WINGS"), ("7-Eleven", r"^7 ELEVEN"),
    ("Casey's", r"^CASEYS"), ("Pizza Ranch", r"^PIZZA RANCH"), ("Hardee's", r"^HARDEES"), ("Carl's Jr.", r"^CARLS JR"),
    ("Jack in the Box", r"^JACK IN THE BOX"), ("Del Taco", r"^DEL TACO"), ("Whataburger", r"^WHATABURGER"), ("In-N-Out Burger", r"^IN N OUT"),
    ("Café Rio", r"^CAFE RIO"), ("Costa Vida", r"^COSTA VIDA"), ("Cafe Yumm!", r"^CAFE YUMM"), ("Waffle House", r"^WAFFLE HOUSE"),
    ("Perkins", r"^PERKINS (?:RESTAURANT|BAKERY|AMERICAN|FAMILY)|^PERKINS$"), ("Bob Evans", r"^BOB EVANS"), ("Black Bear Diner", r"^BLACK BEAR DINER"),
    ("Native Grill & Wings", r"^NATIVE GRILL"), ("BJ's Restaurant", r"^BJS RESTAURANT|^BJS BREWHOUSE"), ("Twin Peaks", r"^TWIN PEAKS"),
    ("Kneaders", r"^KNEADERS"), ("Swig", r"^SWIG$"), ("Crave Cookies", r"^CRAVE COOKIE"), ("Paris Baguette", r"^PARIS BAGUETTE"),
    ("Sweetgreen", r"^SWEETGREEN"), ("Torchy's Tacos", r"^TORCHYS"), ("Velvet Taco", r"^VELVET TACO"), ("Fuzzy's Taco Shop", r"^FUZZYS TACO"),
    ("Slim Chickens", r"^SLIM CHICKENS"), ("Zaxby's", r"^ZAXBY"), ("Bojangles", r"^BOJANGLES"), ("Church's Chicken", r"^CHURCHS (?:TEXAS )?CHICKEN"),
    ("Hooters", r"^HOOTERS"), ("Dairy Queen", r"^DAIRY QUEEN|^DQ GRILL|^DQ$"),
    # Hawaii's own chains and the Japanese and Filipino chains common here
    ("Zippy's", r"^ZIPPYS"), ("L&L Hawaiian Barbecue", r"^L (?:AND )?L HAWAIIAN|^L AND L DRIVE|^L L HAWAIIAN|^L AND L BARBECUE"),
    ("Ono Hawaiian BBQ", r"^ONO HAWAIIAN B"), ("Rainbow Drive-In", r"^RAINBOW DRIVE IN"), ("Teddy's Bigger Burgers", r"^TEDDYS BIGGER"),
    ("Liliha Bakery", r"^LILIHA BAKERY"), ("Leonard's Bakery", r"^LEONARDS BAKERY|^LEONARDS MALASADA"), ("Island Vintage Coffee", r"^ISLAND VINTAGE"),
    ("Honolulu Coffee", r"^HONOLULU COFFEE"), ("Kona Coffee Purveyors", r"^KONA COFFEE PURVEYORS"), ("Coffee Bean & Tea Leaf", r"^(?:THE )?COFFEE BEAN"),
    ("Pokeworks", r"^POKEWORKS"), ("Poke Bar", r"^POKE BAR"), ("Pioneer Saloon", r"^PIONEER SALOON"), ("Kua Aina", r"^KUA AINA"),
    ("Big City Diner", r"^BIG CITY DINER"), ("Kenny's", r"^KENNYS (?:RESTAURANT|COFFEE)"), ("Ba-Le", r"^BA ?LE (?:SANDWICH|BAKERY|FRENCH)|^BA LE$"),
    ("Genki Sushi", r"^GENKI SUSHI"), ("Sushi Bay", r"^SUSHI BAY"), ("Kozo Sushi", r"^KOZO SUSHI"), ("Marukame Udon", r"^MARUKAME"),
    ("Yoshinoya", r"^YOSHINOYA"), ("Mos Burger", r"^MOS BURGER"), ("Gyu-Kaku", r"^GYU ?KAKU"), ("Shiro's Saimin Haven", r"^SHIROS SAIMIN"),
    ("Jollibee", r"^JOLLIBEE"), ("Max's of Manila", r"^MAXS OF MANILA|^MAXS RESTAURANT"), ("Tanioka's", r"^TANIOKAS"),
    ("Bubba Gump Shrimp Co.", r"^BUBBA GUMP"), ("Cheeseburger in Paradise", r"^CHEESEBURGER (?:IN PARADISE|BEACHWALK|WAIKIKI)"),
    ("Duke's", r"^DUKES (?:WAIKIKI|KAUAI|BEACH HOUSE|CANOE CLUB)"), ("Hula Grill", r"^HULA GRILL"), ("Roy's", r"^ROYS (?:RESTAURANT|WAIKIKI|KO OLINA|HAWAII KAI|BEACH HOUSE|KAANAPALI|WAIKOLOA)|^ROYS$"),
    ("Merriman's", r"^MERRIMANS"), ("Monkeypod Kitchen", r"^MONKEYPOD"), ("Buzz's Steakhouse", r"^BUZZS (?:ORIGINAL )?STEAK"),
    ("Kona Brewing", r"^KONA BREWING|^KONA PUB"), ("Maui Brewing", r"^MAUI BREWING"), ("Tropical Smoothie Cafe", r"^TROPICAL SMOOTHIE"),
    ("Pieology", r"^PIEOLOGY"), ("Bob's Pizza", r"^BOBS PIZZA"), ("Boston's North End Pizza", r"^BOSTONS (?:NORTH END )?PIZZA"),
    ("Brug Bakery", r"^BRUG BAKERY"), ("Chun Wah Kam", r"^CHUN WAH KAM"), ("Shaka Pressed Juice", r"^SHAKA PRESSED"), ("Nalu Health Bar", r"^NALU HEALTH"),
    ("Lahaina Chicken Company", r"^LAHAINA CHICKEN CO"), ("Hawaiian Bros", r"^HAWAIIAN BROS"), ("Rainbow Shave Ice", r"^RAINBOW SHAVE ICE"),
    ("Island Snow", r"^ISLAND SNOW"), ("Ululani's", r"^ULULANIS"), ("Ruby Tuesday", r"^RUBY TUESDAY"), ("Raising Cane's", r"^RAISING CANE"),
    ("Sizzler", r"^SIZZLER"), ("Pho To Chau", r"^PHO TO CHAU"), ("Paris Baguette", r"^PARIS BAGUETTE"),
    ("Coco Ichibanya", r"^COCO ICHIBANYA"), ("Agu Ramen", r"^AGU RAMEN"), ("Musubi Cafe Iyasume", r"^MUSUBI CAFE IYASUME|^IYASUME"),
    ("Kaka'ako Kitchen", r"^KAKAAKO KITCHEN"), ("Foodland", r"^FOODLAND"), ("Times Supermarket", r"^TIMES (?:SUPER ?MARKET|SUPERMARKETS)"),
    ("KTA Super Stores", r"^KTA"), ("Longs Drugs", r"^LONGS DRUGS"), ("ABC Stores", r"^ABC STORE"), ("Safeway", r"^SAFEWAY"),
    ("7-Eleven", r"^7 ELEVEN"), ("Aloha Island Mart", r"^ALOHA ISLAND MART"), ("Minit Stop", r"^MINIT STOP"),
]
_C = [(b, re.compile(p)) for b, p in BRANDS]

# distinctive brands also recognized mid-name ("HALE FAMILY MCDONALDS", "SAII BABA DUNKIN")
_ANYWHERE = [(b, re.compile(p)) for b, p in [("McDonald's", r"\bMC ?DONALDS\b"), ("Dunkin'", r"\bDUNKIN\b"), ("Starbucks", r"\bSTARBUCKS\b"),
             ("Wingstop", r"\bWING ?STOP\b"), ("Culver's", r"\bCULVERS\b"), ("Popeyes", r"\bPOPEYES\b"), ("Chipotle", r"\bCHIPOTLE\b"),
             ("Jimmy John's", r"\bJIMMY JOHNS\b"), ("Taco Bell", r"\bTACO BELL\b"),
             ("L&L Hawaiian Barbecue", r"\bL AND L HAWAII(?:AN)? (?:BBQ|BARBECUE|BAR B Q)\b"), ("Zippy's", r"\bZIPPYS\b")]]


def brand_of(nkey, *more):
    """Brand from the display name, else from Overture's brand label."""
    keys = [k for k in [nkey] + [m for m in more if isinstance(m, str)] if isinstance(k, str)]
    for k in keys:
        for part in [k or ""] + [p.strip() for p in (k or "").split("/")]:
            for b, p in _C:
                if p.search(part):
                    return b
    for k in keys:
        for b, p in _ANYWHERE:
            if p.search(k or ""):
                return b
    return None
