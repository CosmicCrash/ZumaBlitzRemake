import os
import json

d = {
    "path": "",
    "frame_size": {"x": 100, "y": 98},
    "states": [
        {
            "pos": {
                "x": 0,
                "y": 0
            },
            "frames": {
                "x": 1,
                "y": 1
            }
        }
    ],
    "internal": False,
    "batched": False
}

for p,n,fs in os.walk("./images/food_items"):
    for filename in fs:
        print(filename[:-4])
        j = open(f"./sprites/food_items/{filename[:-4]}.json", "w")
        d["path"] = f"images/food_items/{filename}"
        j.write(json.dumps(d, indent=4))
        j.close()