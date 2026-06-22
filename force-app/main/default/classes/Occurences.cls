public with sharing class Occurences {
    List<String> values;
    public Occurences(List<String> listName) {
        this.values = listName;
    }

    public Map<String, Integer> numbOcc(List<String> values)
    {
        Map<String, Integer> counts = new Map<String, Integer>();
        
        for (String s : values)
        {
            if (counts.containsKey(s))
            {
                Integer count = counts.get(s);
                counts.put(s, count + 1);
            }
            else 
            {
                counts.put(s, 1);
            }
        }
        return counts;
    }
}