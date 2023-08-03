for f in 05_dockerimages/*.tar; do
  sudo nerdctl load -i "$f"
done

for f in 05_dockerimages/k8s.io/*.tar; do
  sudo nerdctl -n k8s.io load -i "$f"
done
