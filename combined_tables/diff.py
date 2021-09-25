import difflib

print("==========monster==========\n\n")

file1 = open('Old\monster.csv', 'r')
file2 = open('monster.csv', 'r')

diff = difflib.ndiff(file1.readlines(), file2.readlines())
delta = ''.join(x[2:] for x in diff if x.startswith('+ '))
print(delta)

print("==========dropbox==========\n\n")

file1 = open('Old\dropbox.csv', 'r')
file2 = open('dropbox.csv', 'r')

diff = difflib.ndiff(file1.readlines(), file2.readlines())
delta = ''.join(x[2:] for x in diff if x.startswith('+ '))
print(delta)

input("Press enter to exit ;)")