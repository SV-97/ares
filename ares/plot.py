
import matplotlib.pyplot as plt


# with open("sorted_set.txt", "r") as f:
#    sorted_set = f.read()
with open("convex_hull.txt", "r") as f:
    hull = f.read()
# with open("start.txt", "r") as f:
#    start = f.read()


def parse(string):
    """Parse string of shape "[[1,2],[3,4]]" to list of float"""
    lst = string.replace("[", "").replace("]", "").split(",")
    xs, ys = zip(*[[float(lst[i]), float(lst[i+1])]
                   for i in range(0, len(lst), 2)])
    return list(xs), list(ys)


#ps_x, ps_y = parse(sorted_set)
h_x, h_y = parse(hull)
#s_x, s_y = parse(start)

h_x.append(h_x[0])
h_y.append(h_y[0])

# for i, xy in enumerate(zip(ps_x, ps_y)):
#    plt.annotate(f"{i}", xy)
#plt.scatter(ps_x, ps_y)
plt.scatter(h_x, h_y)
plt.plot(h_x, h_y)
#plt.scatter(s_x, s_y)
#plt.annotate("start", list(zip(s_x, s_y))[0])
plt.gca().invert_yaxis()
plt.show()
